class ProductsController < ApplicationController
  before_action :set_product, only: :show

  def index
    @products = Product.includes(option_groups: :option_values).order(:name)
  end

  def show
  end

  private

  def set_product
    @product = Product.includes(option_groups: :option_values).find(params[:id])
  end
end
