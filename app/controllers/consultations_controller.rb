class ConsultationsController < ApplicationController

  def index
    @full_render = true  # Hide navbar for consultations view
    
    # Load profile if profile_id is provided
    if params[:profile_id].present?
      @profile = Profile.find(params[:profile_id])
      
      # Generate absolute URL for WeChat share image
      @share_image_url = if @profile.avatar.attached?
        url_for(@profile.avatar)
      elsif @profile.avatar_url.present?
        @profile.avatar_url
      else
        # Use a default placeholder image from Unsplash
        "https://images.unsplash.com/photo-1560250097-0b93528c311a?w=400&h=400&fit=crop"
      end
      
      # Convert relative URL to absolute URL if needed
      if @share_image_url.present? && @share_image_url.start_with?('/')
        @share_image_url = "#{request.protocol}#{request.host_with_port}#{@share_image_url}"
      end
    end
  rescue ActiveRecord::RecordNotFound
    redirect_to root_path, alert: '未找到该名片'
  end

  private
  # Write your private methods here
end
