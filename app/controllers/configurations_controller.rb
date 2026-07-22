class ConfigurationsController < ApplicationController
  before_action :set_product, only: [ :new, :update ]

  def new
    session[:configuration] = { @product.id.to_s => {} }
    @current_group = @product.option_groups.first
    @selected_values = {}
    respond_to do |format|
      format.html
      format.turbo_stream
    end
  end

  def update
    group_id = params[:option_group_id]
    value_id = params[:option_value_id]

    if group_id && value_id
      session[:configuration][@product.id.to_s] ||= {}
      session[:configuration][@product.id.to_s][group_id] = value_id
    end

    @selected_values = session[:configuration][@product.id.to_s] || {}
    remaining_groups = @product.option_groups.where.not(id: @selected_values.keys)
    @current_group = remaining_groups.first
    @total_price = calculate_total_price(@product, @selected_values)

    respond_to do |format|
      format.turbo_stream do
        if @current_group
          render turbo_stream: [
            turbo_stream.replace("config_step", partial: "configurations/step", locals: { product: @product, group: @current_group, selected_values: @selected_values }),
            turbo_stream.replace("config_summary", partial: "configurations/summary", locals: { product: @product, selected_values: @selected_values, total_price: @total_price })
          ]
        else
          render turbo_stream: [
            turbo_stream.replace("config_step", partial: "configurations/generate_quote", locals: { product: @product }),
            turbo_stream.replace("config_summary", partial: "configurations/summary", locals: { product: @product, selected_values: @selected_values, total_price: @total_price })
          ]
        end
      end
      format.html { redirect_to new_product_configuration_path(@product) }
    end
  end

  private

  def set_product
    @product = Product.includes(option_groups: :option_values).find(params[:product_id])
  end

  def calculate_total_price(product, selected_values)
    base = product.base_price
    modifiers = selected_values.sum do |group_id, value_id|
      OptionValue.where(id: value_id).pick(:price_modifier) || BigDecimal("0")
    end
    base + modifiers
  end
end
