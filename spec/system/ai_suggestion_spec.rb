require 'rails_helper'

RSpec.describe 'AI Suggestion', type: :system, js: true do
  let!(:product) { create(:product, base_price: 100.0) }
  let!(:color_group) { create(:option_group, name: 'Color', product: product) }
  let!(:red_option) { create(:option_value, option_group: color_group, name: 'Red', price_modifier: 20.0) }

  before do
    driven_by(:selenium_chrome_headless)
  end

  it 'shows a suggested configuration after clicking the button' do
    visit product_path(product)

    click_button 'Suggest Configuration'

    expect(page).to have_selector('#ai_suggestion', text: 'AI Suggested Configuration', wait: 5)
    within '#ai_suggestion' do
      expect(page).to have_content('Color:')
    end
  end
end
