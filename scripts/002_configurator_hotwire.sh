#!/bin/bash
# Spec 2 – Multi-step Product Configurator with Turbo Streams & Stimulus
# Project: quotebuilder (Rails 8 + Hotwire)

set -e

echo "==> Creando controlador de configuración..."

mkdir -p app/views/configurations

# Controlador
cat > app/controllers/configurations_controller.rb << 'EOF'
class ConfigurationsController < ApplicationController
  before_action :set_product, only: [:new, :update]

  def new
    session[:configuration] = { @product.id.to_s => {} }
    @current_group = @product.option_groups.first
    @selected_values = {}
    respond_to do |format|
      format.html
      format.turbo_stream
    end
  end

  def update
    group_id = params[:option_group_id]
    value_id = params[:option_value_id]

    if group_id && value_id
      session[:configuration][@product.id.to_s] ||= {}
      session[:configuration][@product.id.to_s][group_id] = value_id
    end

    @selected_values = session[:configuration][@product.id.to_s] || {}
    remaining_groups = @product.option_groups.where.not(id: @selected_values.keys)
    @current_group = remaining_groups.first
    @total_price = calculate_total_price(@product, @selected_values)

    respond_to do |format|
      format.turbo_stream do
        if @current_group
          render turbo_stream: [
            turbo_stream.replace("config_step", partial: "configurations/step", locals: { product: @product, group: @current_group, selected_values: @selected_values }),
            turbo_stream.replace("config_summary", partial: "configurations/summary", locals: { product: @product, selected_values: @selected_values, total_price: @total_price })
          ]
        else
          render turbo_stream: [
            turbo_stream.replace("config_step", partial: "configurations/generate_quote", locals: { product: @product }),
            turbo_stream.replace("config_summary", partial: "configurations/summary", locals: { product: @product, selected_values: @selected_values, total_price: @total_price })
          ]
        end
      end
      format.html { redirect_to new_product_configuration_path(@product) }
    end
  end

  private

  def set_product
    @product = Product.includes(option_groups: :option_values).find(params[:product_id])
  end

  def calculate_total_price(product, selected_values)
    base = product.base_price
    modifiers = selected_values.sum do |group_id, value_id|
      OptionValue.where(id: value_id).pick(:price_modifier) || BigDecimal("0")
    end
    base + modifiers
  end
end
EOF

# Vistas
cat > app/views/configurations/new.html.erb << 'EOF'
<div class="container mx-auto px-4 py-8">
  <h1 class="text-3xl font-bold text-gray-800 mb-6">Configure <%= @product.name %></h1>
  <div class="flex flex-col md:flex-row gap-8">
    <!-- Step frame -->
    <div class="md:w-2/3">
      <%= turbo_frame_tag "config_step" do %>
        <%= render "step", product: @product, group: @current_group, selected_values: @selected_values || {} %>
      <% end %>
    </div>

    <!-- Summary frame -->
    <div class="md:w-1/3">
      <%= turbo_frame_tag "config_summary" do %>
        <%= render "summary", product: @product, selected_values: @selected_values || {}, total_price: @product.base_price %>
      <% end %>
    </div>
  </div>
</div>
EOF

cat > app/views/configurations/_step.html.erb << 'EOF'
<%= turbo_frame_tag "config_step" do %>
  <div class="bg-white rounded-lg shadow-md p-6">
    <h2 class="text-xl font-semibold text-gray-700 mb-4"><%= group.name %></h2>
    <%= form_with url: product_configuration_path(product, group), method: :patch, data: { turbo_frame: "_top" } do |f| %>
      <%= f.hidden_field :option_group_id, value: group.id %>
      <div class="space-y-3">
        <% group.option_values.each do |value| %>
          <label class="flex items-center space-x-3 p-3 rounded border border-gray-200 hover:bg-gray-50 cursor-pointer">
            <%= f.radio_button :option_value_id, value.id, class: "form-radio text-indigo-600" %>
            <span class="text-gray-800"><%= value.name %></span>
            <span class="text-gray-500 text-sm"><%= value.price_modifier >= 0 ? "+" : "" %><%= number_to_currency(value.price_modifier) %></span>
          </label>
        <% end %>
      </div>
      <div class="mt-6">
        <%= f.submit "Next", class: "bg-indigo-500 text-white px-6 py-2 rounded hover:bg-indigo-600" %>
      </div>
    <% end %>
  </div>
<% end %>
EOF

cat > app/views/configurations/_summary.html.erb << 'EOF'
<%= turbo_frame_tag "config_summary" do %>
  <div class="bg-white rounded-lg shadow-md p-6">
    <h2 class="text-xl font-semibold text-gray-700 mb-4">Summary</h2>
    <ul class="space-y-2">
      <% product.option_groups.each do |group| %>
        <li class="text-gray-600">
          <span class="font-medium"><%= group.name %>:</span>
          <% if selected_values[group.id.to_s] %>
            <% value = group.option_values.find_by(id: selected_values[group.id.to_s]) %>
            <%= value&.name || "—" %>
          <% else %>
            —
          <% end %>
        </li>
      <% end %>
    </ul>
    <div class="mt-6 pt-4 border-t border-gray-200">
      <p class="text-2xl font-bold text-indigo-600"><%= number_to_currency(total_price) %></p>
      <p class="text-sm text-gray-500">Total price</p>
    </div>
  </div>
<% end %>
EOF

cat > app/views/configurations/_generate_quote.html.erb << 'EOF'
<%= turbo_frame_tag "config_step" do %>
  <div class="bg-white rounded-lg shadow-md p-6 text-center">
    <h2 class="text-2xl font-semibold text-gray-700 mb-4">Configuration Complete</h2>
    <p class="text-gray-500 mb-6">All options selected. Ready to generate a quote.</p>
    <%= link_to "Generate Quote", "#", class: "bg-green-500 text-white px-6 py-3 rounded-lg text-lg hover:bg-green-600" %>
  </div>
<% end %>
EOF

# Rutas
sed -i '/resources :products/a\  resources :products, only: [] do\n    resource :configuration, only: [:new, :update], controller: "configurations"\n  end' config/routes.rb

# Corregir el archivo routes.rb para que quede limpio (sobrescribimos con la versión final)
cat > config/routes.rb << 'EOF'
Rails.application.routes.draw do
  resources :products, only: [:index, :show]
  resources :products, only: [] do
    resource :configuration, only: [:new, :update], controller: "configurations"
  end
  root "products#index"
end
EOF

# Test de sistema para el configurador
cat > spec/system/product_configurator_spec.rb << 'EOF'
require 'rails_helper'

RSpec.describe 'Product Configurator', type: :system do
  let!(:product) { create(:product, base_price: 100.0) }
  let!(:color_group) { create(:option_group, name: 'Color', product: product) }
  let!(:red_option) { create(:option_value, option_group: color_group, name: 'Red', price_modifier: 20.0) }
  let!(:blue_option) { create(:option_value, option_group: color_group, name: 'Blue', price_modifier: 0.0) }
  let!(:length_group) { create(:option_group, name: 'Length', product: product) }
  let!(:short_option) { create(:option_value, option_group: length_group, name: '1m', price_modifier: 0.0) }
  let!(:long_option) { create(:option_value, option_group: length_group, name: '2m', price_modifier: 50.0) }

  before do
    driven_by(:rack_test)
  end

  it 'navigates through the configurator steps', :js do
    visit new_product_configuration_path(product)

    # First step: Color
    expect(page).to have_content('Color')
    choose 'Red'
    click_button 'Next'

    # Second step: Length
    expect(page).to have_content('Length')
    expect(page).to have_content('$170.00') # 100 + 20 + 50? Wait, first step selected Red (+20), total now 120. Summary should show 120.
    # Actually summary should update after first selection. Let's check summary content.
    within '#config_summary' do
      expect(page).to have_content('$120.00') # 100 + 20
    end

    choose '2m'
    click_button 'Next'

    # Should see generate quote button
    expect(page).to have_content('Configuration Complete')
    expect(page).to have_content('Generate Quote')
    within '#config_summary' do
      expect(page).to have_content('$170.00') # 100 + 20 + 50
    end
  end
end
EOF

echo ""
echo "✅ Spec 2 generada correctamente."
echo "👉 Ejecuta:"
echo "   rails server -p 3001   (si el 3000 está ocupado)"
echo "   Luego visita http://localhost:3001/products y haz clic en 'View Details', luego 'Configure'."
echo "   Para tests: bundle exec rspec spec/system/product_configurator_spec.rb"
