class Whatsapp::IncomingMessageBaileysService < Whatsapp::IncomingMessageBaseService
  private

  def processed_params
    # Baileys API sends data in a different format than WhatsApp Business API
    # We need to normalize it to match the expected format
    @processed_params ||= normalize_baileys_payload(params)
  end

  def normalize_baileys_payload(baileys_params)
    # Baileys webhook payload structure:
    # {
    #   "key": { "remoteJid": "5511999999999@s.whatsapp.net", "id": "message_id" },
    #   "message": { "conversation": "Hello" },
    #   "messageTimestamp": 1234567890,
    #   "pushName": "Contact Name"
    # }

    return baileys_params if baileys_params[:messages].present? # Already normalized

    # Convert Baileys format to Chatwoot expected format
    normalized = {
      contacts: [],
      messages: []
    }

    # Handle single message from Baileys
    if baileys_params[:key].present? && baileys_params[:message].present?
      # Extract phone number from remoteJid (remove @s.whatsapp.net)
      remote_jid = baileys_params.dig(:key, :remoteJid) || baileys_params.dig(:key, :participant)
      phone_number = remote_jid&.split('@')&.first

      if phone_number
        # Add contact info
        normalized[:contacts] << {
          profile: {
            name: baileys_params[:pushName] || baileys_params[:notifyName] || phone_number
          },
          wa_id: phone_number
        }

        # Process message content
        message_content = extract_message_content(baileys_params[:message])
        message_type = determine_message_type(baileys_params[:message])

        # Add message info
        message = {
          id: baileys_params.dig(:key, :id) || SecureRandom.hex(16),
          from: phone_number,
          timestamp: baileys_params[:messageTimestamp]&.to_s || Time.current.to_i.to_s,
          type: message_type
        }

        # Add content based on message type
        case message_type
        when 'text'
          message[:text] = { body: message_content }
        when 'image', 'video', 'audio', 'document'
          message[message_type.to_sym] = {
            id: baileys_params.dig(:message, message_type.to_sym, :url) || SecureRandom.hex(16),
            caption: baileys_params.dig(:message, message_type.to_sym, :caption),
            mimetype: baileys_params.dig(:message, message_type.to_sym, :mimetype),
            url: baileys_params.dig(:message, message_type.to_sym, :url)
          }
        when 'location'
          location_msg = baileys_params.dig(:message, :locationMessage)
          message[:location] = {
            latitude: location_msg[:degreesLatitude],
            longitude: location_msg[:degreesLongitude],
            name: location_msg[:name],
            address: location_msg[:address],
            url: location_msg[:url]
          }
        when 'contacts'
          contacts_msg = baileys_params.dig(:message, :contactsMessage)
          message[:contacts] = contacts_msg[:contacts]&.map do |contact|
            {
              phones: contact[:phones]&.map { |phone| { phone: phone[:phone] } } || [],
              name: { formatted_name: contact[:displayName] }
            }
          end
        end

        normalized[:messages] << message
      end
    end

    # Handle status updates from Baileys
    if baileys_params[:status].present?
      normalized[:statuses] = [{
        id: baileys_params[:messageId],
        status: map_baileys_status(baileys_params[:status]),
        timestamp: baileys_params[:timestamp]&.to_s || Time.current.to_i.to_s
      }]
    end

    normalized
  end

  def extract_message_content(message)
    return message[:conversation] if message[:conversation].present?
    return message.dig(:extendedTextMessage, :text) if message[:extendedTextMessage].present?
    return message.dig(:imageMessage, :caption) if message[:imageMessage].present?
    return message.dig(:videoMessage, :caption) if message[:videoMessage].present?
    return message.dig(:documentMessage, :caption) if message[:documentMessage].present?
    return message.dig(:audioMessage, :caption) if message[:audioMessage].present?
    
    # For other message types, return empty string
    ''
  end

  def determine_message_type(message)
    return 'text' if message[:conversation].present? || message[:extendedTextMessage].present?
    return 'image' if message[:imageMessage].present?
    return 'video' if message[:videoMessage].present?
    return 'audio' if message[:audioMessage].present?
    return 'document' if message[:documentMessage].present?
    return 'location' if message[:locationMessage].present?
    return 'contacts' if message[:contactsMessage].present?
    
    'text' # Default fallback
  end

  def map_baileys_status(baileys_status)
    # Map Baileys status to WhatsApp Business API status
    case baileys_status.downcase
    when 'sent'
      'sent'
    when 'delivered'
      'delivered'
    when 'read'
      'read'
    when 'failed', 'error'
      'failed'
    else
      'sent'
    end
  end

  def download_attachment_file(attachment_payload)
    # For Baileys, we need to download from the URL provided in the payload
    url = attachment_payload[:url]
    return nil if url.blank?

    # If it's a local Baileys API URL, use the media endpoint
    if url.start_with?('/') || url.include?('baileys-api')
      full_url = url.start_with?('/') ? "#{baileys_api_url}#{url}" : url
      Down.download(full_url, headers: baileys_api_headers)
    else
      # External URL, download directly
      Down.download(url)
    end
  rescue => e
    Rails.logger.error "Failed to download Baileys attachment: #{e.message}"
    nil
  end

  private

  def baileys_api_url
    ENV.fetch('BAILEYS_PROVIDER_DEFAULT_URL', 'http://baileys-api:3025')
  end

  def baileys_api_headers
    {
      'Content-Type' => 'application/json',
      'x-api-key' => ENV.fetch('BAILEYS_PROVIDER_DEFAULT_API_KEY', '')
    }
  end
end 