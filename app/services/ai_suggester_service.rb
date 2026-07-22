class AiSuggesterService
  def self.suggest(product, context = "")
    # Simula una llamada a una API de IA.
    # En producción sustituirías por HTTParty/Faraday a OpenAI/DeepSeek.
    groups = product.option_groups.includes(:option_values)
    config = {}
    groups.each do |group|
      # Escoge un valor aleatorio entre los disponibles
      config[group.id.to_s] = group.option_values.sample.id.to_s
    end
    { product_id: product.id, configuration: config }
  end
end
