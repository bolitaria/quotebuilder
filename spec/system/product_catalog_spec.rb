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
