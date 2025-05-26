class Whatsapp::Providers::BaileysService < Whatsapp::Providers::BaseService
  def send_message(phone_number, message)
    @message = message
    
    if message.attachments.present?
      send_attachment_message(phone_number, message)
    elsif message.content_type == 'input_select'
      send_interactive_text_message(phone_number, message)
    else
      send_text_message(phone_number, message)
    end
  end

  def send_template(phone_number, template_info)
    # Baileys doesn't support templates the same way as WhatsApp Business API
    # We'll send as a regular message for now
    send_text_message(phone_number, OpenStruct.new(content: template_info[:content] || template_info[:name]))
  end

  def sync_templates
    # Baileys doesn't support template syncing like WhatsApp Business API
    # Mark as updated to prevent constant retries
    whatsapp_channel.mark_message_templates_updated
  end

  def validate_provider_config?
    # Validate that we can reach the Baileys API
    response = HTTParty.get("#{baileys_api_url}/status", headers: api_headers)
    response.success?
  rescue
    false
  end

  def api_headers
    {
      'Content-Type' => 'application/json',
      'x-api-key' => whatsapp_channel.provider_config['api_key']
    }
  end

  def media_url(media_id)
    "#{baileys_api_url}/media/#{media_id}"
  end

  private

  def baileys_api_url
    ENV.fetch('BAILEYS_PROVIDER_DEFAULT_URL', 'http://baileys-api:3025')
  end

  def baileys_client_name
    ENV.fetch('BAILEYS_PROVIDER_DEFAULT_CLIENT_NAME', 'default')
  end

  def send_text_message(phone_number, message)
    response = HTTParty.post(
      "#{baileys_api_url}/message/text",
      headers: api_headers,
      body: {
        number: phone_number.gsub('+', ''),
        message: message.content,
        client: baileys_client_name
      }.to_json
    )

    process_response(response)
  end

  def send_attachment_message(phone_number, message)
    attachment = message.attachments.first
    
    response = HTTParty.post(
      "#{baileys_api_url}/message/media",
      headers: api_headers,
      body: {
        number: phone_number.gsub('+', ''),
        caption: message.content,
        media_url: attachment.download_url,
        type: attachment.file_type,
        client: baileys_client_name
      }.to_json
    )

    process_response(response)
  end

  def send_interactive_text_message(phone_number, message)
    # Convert Chatwoot input_select to Baileys format
    buttons = message.content_attributes[:items]&.map do |item|
      {
        buttonText: item['title'],
        buttonId: item['value']
      }
    end

    response = HTTParty.post(
      "#{baileys_api_url}/message/buttons",
      headers: api_headers,
      body: {
        number: phone_number.gsub('+', ''),
        message: message.content,
        buttons: buttons&.first(3), # Baileys supports max 3 buttons
        client: baileys_client_name
      }.to_json
    )

    process_response(response)
  end

  def error_message(response)
    response.parsed_response&.dig('error') || response.parsed_response&.dig('message')
  end
end 