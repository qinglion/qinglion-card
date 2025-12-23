class Admin::MemberCategoriesController < Admin::BaseController
  before_action :set_profile, only: [:update]

  def index
    # 获取所有成员，支持筛选和搜索
    @profiles = Profile.includes(:user)
                      .order(created_at: :desc)
    
    # 按类别筛选
    if params[:category].present?
      if params[:category] == 'uncategorized'
        @profiles = @profiles.where(member_category: nil)
      else
        @profiles = @profiles.where(member_category: params[:category])
      end
    end
    
    # 搜索功能
    if params[:search].present?
      search_term = "%#{params[:search]}%"
      @profiles = @profiles.where(
        "full_name LIKE ? OR email LIKE ? OR title LIKE ?",
        search_term, search_term, search_term
      )
    end
    
    @profiles = @profiles.page(params[:page]).per(20)
    
    # 统计信息
    @total_members = Profile.count
    @categorized_members = Profile.where.not(member_category: nil).count
    @uncategorized_members = Profile.where(member_category: nil).count
    
    # 类别列表
    @categories = Profile::MEMBER_CATEGORIES
  end

  def update
    new_category = params[:member_category]
    
    # 允许设置为空（清除类别）
    if new_category == ''
      new_category = nil
    elsif new_category.present? && !Profile::MEMBER_CATEGORIES.include?(new_category)
      flash[:alert] = '无效的类别'
      redirect_to admin_member_categories_path and return
    end
    
    if @profile.update(member_category: new_category)
      # 使用 Turbo Stream 更新页面
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace(
            "profile_category_#{@profile.id}",
            partial: "admin/member_categories/category_badge",
            locals: { profile: @profile }
          )
        end
        format.html do
          flash[:notice] = '类别已更新'
          redirect_to admin_member_categories_path(page: params[:page], category: params[:filter_category], search: params[:search])
        end
      end
    else
      flash[:alert] = '更新失败'
      redirect_to admin_member_categories_path(page: params[:page], category: params[:filter_category], search: params[:search])
    end
  end

  private

  def set_profile
    @profile = Profile.find(params[:id])
  end
end
