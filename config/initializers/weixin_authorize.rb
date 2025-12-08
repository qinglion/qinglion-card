# WeixinAuthorize configuration
# Only configure if WECHAT_APPID is present (skip during asset precompilation)
if ENV['WECHAT_APPID'].present?
  WeixinAuthorize.configure do |config|
    config.appid = ENV['WECHAT_APPID']
    config.secret = ENV['WECHAT_APPSECRET']
    config.token = ''
    config.access_token_redis_key = 'weixin_access_token'
    config.jsapi_ticket_redis_key = 'weixin_jsapi_ticket'
    config.skip_verify_ssl = true
    config.encoding_aes_key = ''
  end
end
