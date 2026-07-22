#!/bin/bash
# Spec 4 – AI-powered configuration suggestion (mock)
set -e

echo "==> Creando servicio de sugerencia IA..."

cat > app/services/ai_suggester_service.rb << 'EOF'
class AiSuggesterService
  def self.suggest(product, context = "")
    # Simula una llamada a una API de IA.
    # En producción sustituirías por HTTParty/Faraday a OpenAI/DeepSeek.
    groups = product.option_groups.includes(:option_values)
    config = {}
    groups.each do |group|
      # Escoge un valor aleatorio entre los disponibles
      config[group.id.to_s] = group.option_values.sample.id.to_s
    end
    { product_id: product.id, configuration: config }
  end
end
EOF

echo "==> Añadiendo endpoint de sugerencia..."

cat > app/controllers/ai_suggestions_controller.rb << 'EOF'
class AiSuggestionsController < ApplicationController
  def create
    product = Product.find(params[:product_id])
    context = params[:context] || ""
    suggestion = AiSuggesterService.suggest(product, context)

    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.replace(
          "ai_suggestion",
          partial: "ai_suggestions/suggestion",
          locals: { product: product, suggestion: suggestion }
        )
      end
      format.json { render json: suggestion }
    end
  end
end
EOF

echo "==> Creando vistas..."

mkdir -p app/views/ai_suggestions

cat > app/views/ai_suggestions/_suggestion.html.erb << 'EOF'
<%= turbo_frame_tag "ai_suggestion" do %>
  <div class="mt-4 p-4 bg-blue-50 rounded-lg border border-blue-200">
    <h3 class="text-lg font-semibold text-blue-800">AI Suggested Configuration</h3>
    <ul class="list-disc pl-5 mt-2 text-blue-700">
      <% product.option_groups.each do |group| %>
        <% value = group.option_values.find_by(id: suggestion[:configuration][group.id.to_s]) %>
        <li><%= group.name %>: <strong><%= value&.name || "—" %></strong></li>
      <% end %>
    </ul>
    <p class="text-sm text-blue-500 mt-3">Context: <%= params[:context] %></p>
  </div>
<% end %>
EOF

# Insertar el botón en la página de producto (show)
echo "==> Añadiendo botón de sugerencia a la vista de producto..."

sed -i '/Back to Catalog/i\  <%= render "ai_suggestions/suggestion_form", product: @product %>' app/views/products/show.html.erb

cat > app/views/ai_suggestions/_suggestion_form.html.erb << 'EOF'
<div class="mt-6">
  <%= form_with url: product_ai_suggestions_path(product), method: :post, local: false, class: "space-y-3" do |f| %>
    <label class="block text-sm font-medium text-gray-700">Get AI suggestion (context)</label>
    <%= f.text_field :context, placeholder: "e.g., high-traffic warehouse", class: "mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500" %>
    <%= f.submit "Suggest Configuration", class: "bg-blue-500 text-white px-4 py-2 rounded hover:bg-blue-600" %>
  <% end %>
  <%= turbo_frame_tag "ai_suggestion" %>
</div>
EOF

echo "==> Añadiendo ruta..."

sed -i '/resources :products, only: \[\:index, \:show\]/a\    resources :ai_suggestions, only: [:create], module: false' config/routes.rb

# Corregir rutas duplicadas (si las hay)
rails routes > /dev/null 2>&1 || true

echo "✅ Spec 4 generada. Ahora puedes pedir una sugerencia desde la ficha de producto."
