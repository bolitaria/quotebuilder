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
      QuoteGeneratorJob.perform_later(@quote.id) # Se ejecuta inmediatamente por config.active_job.queue_adapter = :inline
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
    send_file Rails.root.join("public", @quote.pdf_path), type: 'application/pdf', disposition: 'inline'
  end

  private

  def set_product
    @product = Product.find(params[:product_id])
  end
end
