class Webhooks::WhatsappController < ActionController::API
  include MetaTokenVerifyConcern

  def process_payload
    if inactive_whatsapp_number?
      Rails.logger.warn("Rejected webhook for inactive WhatsApp number: #{params[:phone_number]}")
      render json: { error: 'Inactive WhatsApp number' }, status: :unprocessable_entity
      return
    end

    # Validate authentication for Baileys provider
    channel = Channel::Whatsapp.find_by(phone_number: params[:phone_number])
    if channel&.provider == 'baileys' && !valid_baileys_authentication?
      Rails.logger.warn("Unauthorized Baileys webhook request for: #{params[:phone_number]}")
      render json: { error: 'Unauthorized' }, status: :unauthorized
      return
    end

    Webhooks::WhatsappEventsJob.perform_later(params.to_unsafe_hash)
    head :ok
  end

  private

  def valid_token?(token)
    channel = Channel::Whatsapp.find_by(phone_number: params[:phone_number])
    return false unless channel.present?

    case channel.provider
    when 'baileys'
      # Baileys uses API key for authentication instead of webhook verify token
      api_key = channel.provider_config['api_key']
      return token == api_key if api_key.present?
    else
      # WhatsApp Cloud and 360Dialog use webhook verify token
      whatsapp_webhook_verify_token = channel.provider_config['webhook_verify_token']
      return token == whatsapp_webhook_verify_token if whatsapp_webhook_verify_token.present?
    end

    false
  end

  def inactive_whatsapp_number?
    phone_number = params[:phone_number]
    return false if phone_number.blank?

    inactive_numbers = GlobalConfig.get_value('INACTIVE_WHATSAPP_NUMBERS').to_s
    return false if inactive_numbers.blank?

    inactive_numbers_array = inactive_numbers.split(',').map(&:strip)
    inactive_numbers_array.include?(phone_number)
  end

  def valid_baileys_authentication?
    # Baileys API uses API key in headers for authentication
    api_key = request.headers['X-API-Key'] || request.headers['Authorization']&.gsub(/^Bearer\s+/, '')
    return false if api_key.blank?

    channel = Channel::Whatsapp.find_by(phone_number: params[:phone_number])
    return false unless channel&.provider == 'baileys'

    configured_api_key = channel.provider_config['api_key']
    api_key == configured_api_key
  end
end
