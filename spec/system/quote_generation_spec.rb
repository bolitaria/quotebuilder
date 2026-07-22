require 'rails_helper'

RSpec.describe 'Quote Generation', type: :system do
  let!(:product) { create(:product, base_price: 100.0) }
  let!(:color_group) { create(:option_group, name: 'Color', product: product) }
  let!(:red_option) { create(:option_value, option_group: color_group, name: 'Red', price_modifier: 20.0) }
  let!(:length_group) { create(:option_group, name: 'Length', product: product) }
  let!(:short_option) { create(:option_value, option_group: length_group, name: '1m', price_modifier: 0.0) }

  before do
    driven_by(:selenium_chrome_headless)
  end

  it 'generates a downloadable PDF after completing configuration' do
    visit new_product_configuration_path(product)

    expect(page).to have_content('Color')
    choose 'Red'
    click_button 'Next'

    expect(page).to have_content('Length')
    choose '1m'
    click_button 'Next'

    expect(page).to have_content('Configuration Complete')
    fill_in 'Name', with: 'John Doe'
    fill_in 'Email', with: 'john@example.com'
    click_button 'Generate Quote'

    expect(page).to have_content('Quote Ready!', wait: 5)
    expect(page).to have_link('Download PDF')
    expect(page).to have_content('$120.00')
  end
end
