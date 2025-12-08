require 'net/http'
require 'json'
require 'digest'

class WechatService < ApplicationService
  CACHE_KEY_ACCESS_TOKEN = 'wechat_access_token'
  CACHE_KEY_JSAPI_TICKET = 'wechat_jsapi_ticket'
  ACCESS_TOKEN_EXPIRES_IN = 7200 # 2 hours
  JSAPI_TICKET_EXPIRES_IN = 7200 # 2 hours

  def initialize(url)
    @url = url
    @appid = ENV['WECHAT_APPID']
    @appsecret = ENV['WECHAT_APPSECRET']
  end

  def call
    return error_result('WeChat AppID or AppSecret not configured') if @appid.blank? || @appsecret.blank?

    jsapi_ticket = get_jsapi_ticket
    return error_result('Failed to get jsapi_ticket') if jsapi_ticket.blank?

    signature_data = generate_signature(jsapi_ticket)
    {
      success: true,
      data: signature_data
    }
  rescue StandardError => e
    Rails.logger.error("WechatService error: #{e.message}")
    error_result(e.message)
  end

  private

  def get_access_token
    cached = Rails.cache.read(CACHE_KEY_ACCESS_TOKEN)
    return cached if cached.present?

    uri = URI("https://api.weixin.qq.com/cgi-bin/token")
    params = {
      grant_type: 'client_credential',
      appid: @appid,
      secret: @appsecret
    }
    uri.query = URI.encode_www_form(params)

    Rails.logger.info("Requesting access_token from WeChat API")
    response = Net::HTTP.get_response(uri)
    result = JSON.parse(response.body)

    Rails.logger.info("WeChat access_token response: #{result.inspect}")

    if result['access_token'].present?
      access_token = result['access_token']
      # Cache for 7000 seconds (slightly less than 7200 to be safe)
      Rails.cache.write(CACHE_KEY_ACCESS_TOKEN, access_token, expires_in: 7000.seconds)
      access_token
    else
      Rails.logger.error("Failed to get access_token: errcode=#{result['errcode']}, errmsg=#{result['errmsg']}")
      nil
    end
  rescue StandardError => e
    Rails.logger.error("Exception getting access_token: #{e.message}")
    nil
  end

  def get_jsapi_ticket
    cached = Rails.cache.read(CACHE_KEY_JSAPI_TICKET)
    return cached if cached.present?

    access_token = get_access_token
    if access_token.blank?
      Rails.logger.error("Cannot get jsapi_ticket: access_token is blank")
      return nil
    end

    uri = URI("https://api.weixin.qq.com/cgi-bin/ticket/getjsapi_ticket")
    params = {
      access_token: access_token,
      type: 'jsapi'
    }
    uri.query = URI.encode_www_form(params)

    Rails.logger.info("Requesting jsapi_ticket from WeChat API")
    response = Net::HTTP.get_response(uri)
    result = JSON.parse(response.body)

    Rails.logger.info("WeChat jsapi_ticket response: #{result.inspect}")

    if result['ticket'].present?
      ticket = result['ticket']
      # Cache for 7000 seconds (slightly less than 7200 to be safe)
      Rails.cache.write(CACHE_KEY_JSAPI_TICKET, ticket, expires_in: 7000.seconds)
      ticket
    else
      Rails.logger.error("Failed to get jsapi_ticket: errcode=#{result['errcode']}, errmsg=#{result['errmsg']}")
      nil
    end
  rescue StandardError => e
    Rails.logger.error("Exception getting jsapi_ticket: #{e.message}")
    nil
  end

  def generate_signature(jsapi_ticket)
    timestamp = Time.now.to_i.to_s
    nonce_str = SecureRandom.hex(8)

    # Remove fragment (#) from URL as per WeChat requirements
    url = @url.split('#')[0]

    # Build signature string: jsapi_ticket=XXX&noncestr=XXX&timestamp=XXX&url=XXX
    string_to_sign = "jsapi_ticket=#{jsapi_ticket}&noncestr=#{nonce_str}&timestamp=#{timestamp}&url=#{url}"
    signature = Digest::SHA1.hexdigest(string_to_sign)

    {
      appId: @appid,
      timestamp: timestamp,
      nonceStr: nonce_str,
      signature: signature,
      url: url
    }
  end

  def error_result(message)
    {
      success: false,
      error: message
    }
  end
end
