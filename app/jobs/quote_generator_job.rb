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
