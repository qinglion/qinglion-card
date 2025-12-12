class DashboardsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_profile

  def index
    # Redirect to onboarding if profile is not completed
    if @profile.needs_onboarding?
      redirect_to onboardings_path
      return
    end

    @recent_chat_sessions = @profile.chat_sessions.recent.limit(10)
    @stats = {
      total_chats: @profile.chat_sessions.count,
      active_chats: @profile.chat_sessions.active.count,
      total_messages: @profile.chat_messages.count,
      case_studies_count: @profile.case_studies.count,
      honors_count: @profile.honors.count
    }
  end

  def case_studies
    @case_studies = @profile.case_studies.page(params[:page]).per(20)
  end

  def honors
    @honors = @profile.honors.page(params[:page]).per(20)
  end

  def settings
    # Edit Profile model (name card information)
  end

  def share_card
    require 'rqrcode'
    
    # Generate share URL with profile_id
    share_url = card_url(@profile.slug, profile_id: @profile.id)
    
    # Generate QR code
    qrcode = RQRCode::QRCode.new(share_url)
    
    # Convert to SVG for display
    @qr_svg = qrcode.as_svg(
      color: '000',
      shape_rendering: 'crispEdges',
      module_size: 6,
      standalone: true,
      use_path: true
    )
    
    @share_url = share_url
  end

  def update_settings
    if @profile.update(profile_params)
      # Trigger AI extraction of specializations in background
      ExtractProfileSpecializationsJob.perform_later(@profile.id)
      
      # If coming from onboarding, redirect back to onboarding
      if params[:from_onboarding]
        redirect_to onboardings_path, notice: '保存成功！继续完善信息或预览名片'
      else
        redirect_to dashboards_path, notice: '名片信息更新成功'
      end
    else
      if params[:from_onboarding]
        render 'onboardings/index', status: :unprocessable_entity
      else
        render :settings, status: :unprocessable_entity
      end
    end
  end

  private

  def profile_params
    params.require(:profile).permit(
      :full_name, :title, :company, :phone, :email, :location, :bio,
      :avatar, :background_image, :department, :slug,
      :service_advantage_1_title, :service_advantage_1_description,
      :service_advantage_2_title, :service_advantage_2_description,
      :service_advantage_3_title, :service_advantage_3_description,
      :service_process_1_title, :service_process_1_description,
      :service_process_2_title, :service_process_2_description,
      :service_process_3_title, :service_process_3_description,
      :service_process_4_title, :service_process_4_description,
      :cta_title, :cta_description,
      stats: [:years_experience, :cases_handled, :clients_served, :success_rate]
    )
  end
  
  def set_profile
    @profile = current_user.profile || current_user.create_profile(
      full_name: current_user.name || current_user.email.split('@').first.titleize,
      title: 'Professional',
      email: current_user.email
    )
  end
end