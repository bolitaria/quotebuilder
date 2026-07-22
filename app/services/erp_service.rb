class ErpService
  def self.send_quote(quote)
    # Simula el envío a un ERP externo.
    # En producción usaríamos una URL de webhook configurable.
    Rails.logger.info "[ERP] Sending quote #{quote.id} to ERP..."
    # Podríamos hacer una petición HTTP real a un endpoint de prueba:
    # response = Faraday.post(ENV['ERP_WEBHOOK_URL'], quote.to_json)
    # Por ahora simplemente registramos éxito.
    Rails.logger.info "[ERP] Quote #{quote.id} sent successfully."
    true
  rescue => e
    Rails.logger.error "[ERP] Failed to send quote #{quote.id}: #{e.message}"
    false
  end
end
