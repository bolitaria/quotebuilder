class QuotesController < ApplicationController
  before_action :set_product, only: [:create]

  def create
    config_data = session.dig(:configuration, @product.id.to_s) || {}
    @quote = Quote.new(
      product: @product,
      customer_name: params[:customer_name],
      customer_email: params[:customer_email],
      configuration_data: config_data,
      status: 'draft'
    )

    if @quote.save
      session[:configuration]&.delete(@product.id.to_s)
      # Con queue_adapter inline, el job se ejecuta inmediatamente
      QuoteGeneratorJob.perform_later(@quote.id)
      @quote.reload
      render turbo_stream: turbo_stream.replace(
        "config_step",
        partial: "quotes/download_link",
        locals: { quote: @quote }
      )
    else
      render turbo_stream: turbo_stream.replace(
        "config_step",
        partial: "quotes/error",
        locals: { errors: @quote.errors.full_messages }
      ), status: :unprocessable_entity
    end
  end

  def show
    @quote = Quote.find(params[:id])
    safe_path = sanitize_pdf_path(@quote.pdf_path)
    # brakeman: disable SendFile
    send_file safe_path, type: 'application/pdf', disposition: 'inline'
  end

  private

  def set_product
    @product = Product.find(params[:product_id])
  end

  def sanitize_pdf_path(pdf_path)
    base_dir = Rails.root.join("public", "quotes")
    full_path = base_dir.join(pdf_path).expand_path

    unless full_path.to_s.start_with?(base_dir.to_s)
      raise ActionController::RoutingError, 'Not Found'
    end

    full_path
  end
end
