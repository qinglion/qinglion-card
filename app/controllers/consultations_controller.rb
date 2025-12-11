class ConsultationsController < ApplicationController

  def index
    @full_render = true  # Hide navbar for consultations view
    
    # Load profile if profile_id is provided
    if params[:profile_id].present?
      @profile = Profile.find(params[:profile_id])
    end
  rescue ActiveRecord::RecordNotFound
    redirect_to root_path, alert: '未找到该名片'
  end

  private
  # Write your private methods here
end
