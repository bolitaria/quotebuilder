#!/bin/bash
# Spec 3 – Quote generation with Solid Queue, PDF & mock ERP
# Project: quotebuilder (Rails 8 + Hotwire)

set -e

echo "==> Creando servicio ERP (mock)..."
mkdir -p app/services

cat > app/services/erp_service.rb << 'EOF'
class ErpService
  def self.send_quote(quote)
    # Simula el envío a un ERP externo.
    # En producción usaríamos una URL de webhook configurable.
    Rails.logger.info "[ERP] Sending quote #{quote.id} to ERP..."
    # Podríamos hacer una petición HTTP real a un endpoint de prueba:
    # response = Faraday.post(ENV['ERP_WEBHOOK_URL'], quote.to_json)
    # Por ahora simplemente registramos éxito.
    Rails.logger.info "[ERP] Quote #{quote.id} sent successfully."
    true
  rescue => e
    Rails.logger.error "[ERP] Failed to send quote #{quote.id}: #{e.message}"
    false
  end
end
EOF

echo "==> Creando job de generación de presupuesto..."

cat > app/jobs/quote_generator_job.rb << 'EOF'
class QuoteGeneratorJob < ApplicationJob
  queue_as :default

  def perform(quote_id)
    quote = Quote.find(quote_id)
    return unless quote.status == "draft"

    # Calcular precio final
    quote.total_price = quote.calculate_total_price_from_config
    quote.status = "completed"

    # Generar PDF
    pdf_path = generate_pdf(quote)
    quote.pdf_path = pdf_path

    quote.save!

    # Enviar a ERP (simulado)
    ErpService.send_quote(quote)

    # Notificar al frontend vía Turbo Streams
    Turbo::StreamsChannel.broadcast_replace_to(
      "quote_#{quote.id}",
      target: "config_step",
      partial: "quotes/download_link",
      locals: { quote: quote }
    )
  end

  private

  def generate_pdf(quote)
    require 'prawn'
    pdf = Prawn::Document.new
    pdf.text "Quote ##{quote.id}", size: 24, style: :bold
    pdf.move_down 20
    pdf.text "Customer: #{quote.customer_name}"
    pdf.text "Email: #{quote.customer_email}"
    pdf.move_down 15
    pdf.text "Product: #{quote.product.name} (#{quote.product.code})"
    pdf.text "Base price: #{quote.product.base_price}"
    pdf.move_down 10
    pdf.text "Selected options:"
    quote.configuration_data.each do |group_id, value_id|
      group = OptionGroup.find_by(id: group_id)
      value = OptionValue.find_by(id: value_id)
      if group && value
        pdf.text "  #{group.name}: #{value.name} (#{value.price_modifier})"
      end
    end
    pdf.move_down 10
    pdf.text "Total: #{quote.total_price}", size: 16, style: :bold
    file_path = Rails.root.join("public", "quotes", "#{quote.id}.pdf")
    FileUtils.mkdir_p(File.dirname(file_path))
    pdf.render_file(file_path)
    "/quotes/#{quote.id}.pdf"
  end
end
EOF

echo "==> Añadiendo método calculate_total_price_from_config a Quote..."

# Añadir el método al modelo Quote si no existe (lo añadimos al final)
cat >> app/models/quote.rb << 'EOF'

  def calculate_total_price_from_config
    return BigDecimal('0') unless product
    base = product.base_price
    return base unless configuration_data.is_a?(Hash) && configuration_data.present?

    modifiers = configuration_data.sum do |_group_id, value_id|
      OptionValue.where(id: value_id).pick(:price_modifier) || BigDecimal('0')
    end
    base + modifiers
  end
EOF

# Y añadimos el atributo pdf_path a la tabla quotes (migración)
rails generate migration AddPdfPathToQuotes pdf_path:string
rails db:migrate

# Recrear el modelo Quote para incluir el nuevo atributo (ya está)

echo "==> Creando controlador de presupuestos..."

cat > app/controllers/quotes_controller.rb << 'EOF'
class QuotesController < ApplicationController
  before_action :set_product, only: [:create]

  def create
    # Construir presupuesto con los datos del configurador (sesión)
    config_data = session.dig(:configuration, @product.id.to_s) || {}
    @quote = Quote.new(
      product: @product,
      customer_name: params[:customer_name],
      customer_email: params[:customer_email],
      configuration_data: config_data,
      status: 'draft'
    )

    if @quote.save
      # Limpiar configuración de la sesión
      session[:configuration]&.delete(@product.id.to_s)

      # Encolar el job
      QuoteGeneratorJob.perform_later(@quote.id)

      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace(
            "config_step",
            partial: "quotes/processing",
            locals: { quote: @quote }
          )
        end
      end
    else
      # En caso de error (poco probable), mostrar mensaje
      render turbo_stream: turbo_stream.replace(
        "config_step",
        partial: "quotes/error",
        locals: { errors: @quote.errors.full_messages }
      ), status: :unprocessable_entity
    end
  end

  def show
    @quote = Quote.find(params[:id])
    send_file Rails.root.join("public", @quote.pdf_path), type: 'application/pdf', disposition: 'inline'
  end

  private

  def set_product
    @product = Product.find(params[:product_id])
  end
end
EOF

echo "==> Creando vistas..."

mkdir -p app/views/quotes

cat > app/views/quotes/_processing.html.erb << 'EOF'
<%= turbo_frame_tag "config_step" do %>
  <div class="bg-white rounded-lg shadow-md p-6 text-center">
    <h2 class="text-xl font-semibold text-gray-700 mb-4">Generating Quote...</h2>
    <div class="animate-spin rounded-full h-12 w-12 border-b-2 border-indigo-500 mx-auto"></div>
    <p class="text-gray-500 mt-4">We are preparing your quote. This may take a few seconds.</p>
    <%= turbo_stream_from "quote_#{quote.id}" %>
  </div>
<% end %>
EOF

cat > app/views/quotes/_download_link.html.erb << 'EOF'
<%= turbo_frame_tag "config_step" do %>
  <div class="bg-white rounded-lg shadow-md p-6 text-center">
    <h2 class="text-2xl font-semibold text-green-600 mb-4">Quote Ready!</h2>
    <p class="text-gray-700 mb-6">Your quote has been generated successfully.</p>
    <%= link_to "Download PDF", quote_path(quote), class: "inline-block bg-green-500 text-white px-6 py-3 rounded-lg text-lg hover:bg-green-600", target: "_blank" %>
    <p class="text-sm text-gray-500 mt-4">Quote total: <%= number_to_currency(quote.total_price) %></p>
  </div>
<% end %>
EOF

cat > app/views/quotes/_error.html.erb << 'EOF'
<%= turbo_frame_tag "config_step" do %>
  <div class="bg-red-50 rounded-lg p-6">
    <h2 class="text-lg font-semibold text-red-600">Error generating quote</h2>
    <ul class="list-disc pl-5 mt-2">
      <% errors.each do |msg| %>
        <li class="text-red-500"><%= msg %></li>
      <% end %>
    </ul>
  </div>
<% end %>
EOF

echo "==> Actualizando la vista de configuración para incluir campos de cliente..."

# Modificar el partial _generate_quote.html.erb para incluir formulario con nombre/email
cat > app/views/configurations/_generate_quote.html.erb << 'EOF'
<%= turbo_frame_tag "config_step" do %>
  <div class="bg-white rounded-lg shadow-md p-6">
    <h2 class="text-2xl font-semibold text-gray-700 mb-4">Configuration Complete</h2>
    <p class="text-gray-500 mb-6">All options selected. Please fill in your details to receive a quote.</p>
    <%= form_with url: product_quotes_path(@product), method: :post, local: false, class: "space-y-4" do |f| %>
      <div>
        <%= f.label :customer_name, "Name", class: "block text-sm font-medium text-gray-700" %>
        <%= f.text_field :customer_name, required: true, class: "mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500" %>
      </div>
      <div>
        <%= f.label :customer_email, "Email", class: "block text-sm font-medium text-gray-700" %>
        <%= f.email_field :customer_email, required: true, class: "mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500" %>
      </div>
      <%= f.submit "Generate Quote", class: "bg-green-500 text-white px-6 py-3 rounded-lg text-lg hover:bg-green-600 cursor-pointer" %>
    <% end %>
  </div>
<% end %>
EOF

echo "==> Configurando rutas..."

cat > config/routes.rb << 'EOF'
Rails.application.routes.draw do
  resources :products, only: [:index, :show] do
    resource :configuration, only: [:new, :update], controller: "configurations"
    resources :quotes, only: [:create]
  end
  resources :quotes, only: [:show]  # para descargar PDF
  root "products#index"
end
EOF

echo "==> Añadiendo test de sistema para generación de presupuesto..."

cat > spec/system/quote_generation_spec.rb << 'EOF'
require 'rails_helper'

RSpec.describe 'Quote Generation', type: :system do
  let!(:product) { create(:product, base_price: 100.0) }
  let!(:color_group) { create(:option_group, name: 'Color', product: product) }
  let!(:red_option) { create(:option_value, option_group: color_group, name: 'Red', price_modifier: 20.0) }
  let!(:length_group) { create(:option_group, name: 'Length', product: product) }
  let!(:short_option) { create(:option_value, option_group: length_group, name: '1m', price_modifier: 0.0) }

  before do
    # En test ejecutamos los jobs inline para que el PDF se genere inmediatamente
    ActiveJob::Base.queue_adapter = :inline
    driven_by(:rack_test)   # el envío de formularios funciona con rack_test, no necesitamos JS real para el flujo básico
  end

  after do
    ActiveJob::Base.queue_adapter = :test
  end

  it 'generates a downloadable PDF after completing configuration' do
    visit new_product_configuration_path(product)

    # Primer paso de configuración
    choose 'Red'
    click_button 'Next'

    # Segundo paso (último)
    choose '1m'
    click_button 'Next'

    # Ahora deberíamos ver el formulario con nombre y email
    expect(page).to have_content('Configuration Complete')
    fill_in 'Name', with: 'John Doe'
    fill_in 'Email', with: 'john@example.com'
    click_button 'Generate Quote'

    # El job se ejecuta inmediatamente, así que deberíamos ver el enlace de descarga
    expect(page).to have_content('Quote Ready!')
    expect(page).to have_link('Download PDF')
    expect(page).to have_content('$120.00')  # 100 + 20
  end
end
EOF

echo ""
echo "✅ Spec 3 generada correctamente."
echo "👉 Para probar localmente:"
echo "   - Asegúrate de que Solid Queue está corriendo: bundle exec solid_queue start"
echo "   - O ejecuta los jobs inline en development (config/environments/development.rb: config.active_job.queue_adapter = :inline)"
echo "   - Luego levanta el servidor: rails server -p 3001"
echo "   - Sigue el flujo de configuración hasta generar un presupuesto."
echo "   - Para tests: bundle exec rspec spec/system/quote_generation_spec.rb"
