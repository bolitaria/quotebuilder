require 'rails_helper'

RSpec.describe 'AI Suggestion', type: :system do
  let!(:product) { create(:product, base_price: 100.0) }
  let!(:color_group) { create(:option_group, name: 'Color', product: product) }
  let!(:red_option) { create(:option_value, option_group: color_group, name: 'Red', price_modifier: 20.0) }
  let!(:blue_option) { create(:option_value, option_group: color_group, name: 'Blue', price_modifier: 0.0) }

  before do
    driven_by(:rack_test)   # la sugerencia se carga vía Turbo Frame, pero rack_test puede manejarlo porque es un POST normal con redirect? Realmente es turbo_stream, pero sin JS renderiza el HTML del turbo_stream? Con rack_test no se ejecuta Turbo, así que la respuesta turbo_stream no actualiza la página. Mejor usar selenium para simular la interacción real.
    # Para que el test funcione correctamente y demuestre Hotwire, usaremos selenium_headless.
    driven_by(:selenium_chrome_headless)
  end

  it 'shows a suggested configuration after submitting context' do
    visit product_path(product)

    fill_in 'Get AI suggestion (context)', with: 'high-traffic'
    click_button 'Suggest Configuration'

    # Esperamos que aparezca la sección con la sugerencia
    expect(page).to have_content('AI Suggested Configuration', wait: 5)
    # La sugerencia escoge un valor aleatorio; solo verificamos que hay al menos un <li> con Color:
    within '#ai_suggestion' do
      expect(page).to have_content('Color:')
    end
  end
end
