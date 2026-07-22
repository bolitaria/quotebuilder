#!/bin/bash
# Spec 1 – Product Catalog with Turbo Frames
# Project: quotebuilder (Rails 8 + Hotwire)

set -e

echo "==> Creando controlador y vistas..."

# Generar controlador (si no existe)
if [ ! -f app/controllers/products_controller.rb ]; then
  rails generate controller Products index show --no-test-framework --no-helper
fi

# Sobrescribir controlador con lógica correcta
cat > app/controllers/products_controller.rb << 'EOF'
class ProductsController < ApplicationController
  before_action :set_product, only: :show

  def index
    @products = Product.includes(option_groups: :option_values).order(:name)
  end

  def show
  end

  private

  def set_product
    @product = Product.includes(option_groups: :option_values).find(params[:id])
  end
end
EOF

# Vistas con Turbo Frames
cat > app/views/products/index.html.erb << 'EOF'
<div class="container mx-auto px-4 py-8">
  <h1 class="text-3xl font-bold text-gray-800 mb-6">Product Catalog</h1>
  <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
    <% @products.each do |product| %>
      <%= turbo_frame_tag "product_#{product.id}" do %>
        <div class="bg-white rounded-lg shadow-md hover:shadow-lg transition p-4">
          <h2 class="text-xl font-semibold text-gray-700"><%= product.name %></h2>
          <p class="text-gray-500 text-sm"><%= product.category %></p>
          <p class="text-2xl font-bold text-indigo-600 mt-2"><%= number_to_currency(product.base_price) %></p>
          <%= link_to "View Details", product_path(product), class: "mt-3 inline-block bg-indigo-500 text-white px-4 py-2 rounded hover:bg-indigo-600", data: { turbo_frame: "product_#{product.id}" } %>
        </div>
      <% end %>
    <% end %>
  </div>
</div>
EOF

cat > app/views/products/show.html.erb << 'EOF'
<%= turbo_frame_tag "product_#{@product.id}" do %>
  <div class="container mx-auto px-4 py-8">
    <div class="bg-white rounded-lg shadow-md p-6 max-w-2xl mx-auto">
      <h1 class="text-3xl font-bold text-gray-800 mb-4"><%= @product.name %></h1>
      <p class="text-gray-500 text-sm">Code: <%= @product.code %> | Category: <%= @product.category %></p>
      <p class="text-3xl font-bold text-indigo-600 my-4"><%= number_to_currency(@product.base_price) %></p>

      <h2 class="text-xl font-semibold text-gray-700 mt-6 mb-2">Options</h2>
      <ul class="space-y-4">
        <% @product.option_groups.each do |group| %>
          <li>
            <p class="font-medium text-gray-600"><%= group.name %></p>
            <ul class="list-disc list-inside pl-4">
              <% group.option_values.each do |value| %>
                <li class="text-gray-500"><%= value.name %> (<%= number_to_currency(value.price_modifier) %>)</li>
              <% end %>
            </ul>
          </li>
        <% end %>
      </ul>

      <div class="mt-6 flex space-x-3">
        <%= link_to "Configure", "#", class: "bg-green-500 text-white px-4 py-2 rounded hover:bg-green-600" %>
        <%= link_to "Back to Catalog", products_path, class: "bg-gray-300 text-gray-700 px-4 py-2 rounded hover:bg-gray-400", data: { turbo_frame: "product_#{@product.id}" } %>
      </div>
    </div>
  </div>
<% end %>
EOF

# Rutas
cat > config/routes.rb << 'EOF'
Rails.application.routes.draw do
  resources :products, only: [:index, :show]
  root "products#index"
end
EOF

# Test de sistema para el catálogo
mkdir -p spec/system
cat > spec/system/product_catalog_spec.rb << 'EOF'
require 'rails_helper'

RSpec.describe 'Product Catalog', type: :system do
  let!(:product) { create(:product, name: 'Test Barrier', code: 'TEST-001', base_price: 299.99, category: 'Barriers') }

  before do
    driven_by(:rack_test)
    create(:option_group, name: 'Color', product: product) do |group|
      create(:option_value, option_group: group, name: 'Red', price_modifier: 10.0)
    end
  end

  it 'displays a list of products on the root page' do
    visit root_path
    expect(page).to have_content('Test Barrier')
    expect(page).to have_content('$299.99')
  end

  it 'shows product details when clicking on a product card', :js do
    visit root_path
    click_on 'View Details'
    expect(page).to have_content('Test Barrier')
    expect(page).to have_content('Code: TEST-001')
    expect(page).to have_content('Red ($10.00)')
  end

  it 'returns to the catalog from product details', :js do
    visit product_path(product)
    click_on 'Back to Catalog'
    expect(page).to have_content('Product Catalog')
    expect(page).to have_selector('.grid')
  end
end
EOF

echo ""
echo "✅ Spec 1 generada correctamente."
echo "👉 Ejecuta:"
echo "   rails server"
echo "   Luego visita http://localhost:3000 para ver el catálogo."
echo "   Para tests: bundle exec rspec spec/system/product_catalog_spec.rb"
