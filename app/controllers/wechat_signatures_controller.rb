class WechatSignaturesController < ApplicationController
  skip_before_action :verify_authenticity_token, only: [:create]

  def create
    url = params[:url]

    if url.blank?
      render json: { success: false, error: 'URL parameter is required' }, status: :bad_request
      return
    end

    service = WechatService.new(url)
    result = service.call

    if result[:success]
      render json: {
        success: true,
        data: result[:data]
      }
    else
      render json: {
        success: false,
        error: result[:error]
      }, status: :internal_server_error
    end
  end
end
