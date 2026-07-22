class AiSuggestionsController < ApplicationController
  def create
    product = Product.find(params[:product_id])
    context = params[:context] || ""
    suggestion = AiSuggesterService.suggest(product, context)

    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.replace(
          "ai_suggestion",
          partial: "ai_suggestions/suggestion",
          locals: { product: product, suggestion: suggestion }
        )
      end
      format.json { render json: suggestion }
    end
  end
end
