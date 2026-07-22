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
    driven_by(:selenium_headless)
  end

  it 'navigates through the configurator steps and updates summary' do
    visit new_product_configuration_path(product)

    # First step: Color
    expect(page).to have_content('Color')
    choose 'Red'
    click_button 'Next'

    # Should be on Length step, summary shows updated price
    expect(page).to have_content('Length')
    within '#config_summary' do
      expect(page).to have_content('$120.00') # base 100 + red 20
    end

    choose '2m'
    click_button 'Next'

    # Should see Generate Quote
    expect(page).to have_content('Configuration Complete')
    within '#config_summary' do
      expect(page).to have_content('$170.00') # 100 + 20 + 50
    end
  end
end
