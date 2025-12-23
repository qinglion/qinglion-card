class CardsController < ApplicationController
  skip_before_action :authenticate_user!, only: [:show]

  def show
    @full_render = true  # Hide navbar for card view
    @profile = Profile.friendly.find(params[:id])
    
    # Parse text fields into arrays
    @case_studies = parse_text_to_list(@profile.case_studies_text)
    @honors = parse_text_to_list(@profile.honors_text)
    
    # Track the share source profile (for WeChat share scenario)
    @source_profile_id = params[:profile_id]
    if @source_profile_id.present?
      @source_profile = Profile.find_by(id: @source_profile_id)
    end
    
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
  rescue ActiveRecord::RecordNotFound
    redirect_to root_path, alert: '找不到该专业名片'
  end

  private
  
  def parse_text_to_list(text)
    return [] if text.blank?
    text.split("\n").map(&:strip).reject(&:blank?)
  end
end
