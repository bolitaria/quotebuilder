require 'rails_helper'

RSpec.describe 'Product Configurator', type: :system, js: true do
  let!(:product) { create(:product, base_price: 100.0) }
  let!(:color_group) { create(:option_group, name: 'Color', product: product) }
  let!(:red_option) { create(:option_value, option_group: color_group, name: 'Red', price_modifier: 20.0) }
  let!(:blue_option) { create(:option_value, option_group: color_group, name: 'Blue', price_modifier: 0.0) }
  let!(:length_group) { create(:option_group, name: 'Length', product: product) }
  let!(:short_option) { create(:option_value, option_group: length_group, name: '1m', price_modifier: 0.0) }
  let!(:long_option) { create(:option_value, option_group: length_group, name: '2m', price_modifier: 50.0) }

  before do
    driven_by(:selenium_chrome_headless)
  end

  it 'navigates through the configurator steps and updates summary' do
    visit new_product_configuration_path(product)

    # First step
    expect(page).to have_content('Color')
    choose 'Red'
    click_button 'Next'

    # Wait for Turbo to update
    expect(page).to have_content('Length')
    expect(page).to have_selector('#config_summary', text: '$120.00', wait: 5)

    choose '2m'
    click_button 'Next'

    expect(page).to have_content('Configuration Complete')
    expect(page).to have_selector('#config_summary', text: '$170.00', wait: 5)
  end
end
