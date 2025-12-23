class Admin::RenewalsController < Admin::BaseController
  before_action :set_renewal, only: [:destroy]

  def index
    # 获取所有续费记录，支持筛选和搜索
    @renewals = Renewal.includes(profile: :user)
                      .recent
    
    # 按成员筛选
    if params[:profile_id].present?
      @renewals = @renewals.where(profile_id: params[:profile_id])
    end
    
    # 按日期范围筛选
    if params[:start_date].present?
      @renewals = @renewals.where('payment_date >= ?', params[:start_date])
    end
    
    if params[:end_date].present?
      @renewals = @renewals.where('payment_date <= ?', params[:end_date])
    end
    
    # 搜索成员姓名
    if params[:search].present?
      search_term = "%#{params[:search]}%"
      @renewals = @renewals.joins(:profile).where(
        "profiles.full_name LIKE ? OR profiles.email LIKE ?",
        search_term, search_term
      )
    end
    
    @renewals = @renewals.page(params[:page]).per(20)
    
    # 统计信息
    @total_renewals = Renewal.count
    @total_amount = Renewal.sum(:amount)
    @this_month_amount = Renewal.where(
      payment_date: Time.current.beginning_of_month..Time.current.end_of_month
    ).sum(:amount)
    
    # 如果按成员筛选，计算该成员的总收款
    if params[:profile_id].present?
      @selected_profile = Profile.find_by(id: params[:profile_id])
      @profile_total_amount = Renewal.where(profile_id: params[:profile_id]).sum(:amount)
      @profile_renewal_count = Renewal.where(profile_id: params[:profile_id]).count
    end
    
    # 获取所有成员用于下拉选择
    @profiles = Profile.order(:full_name)
  end

  def new
    @renewal = Renewal.new
    @profiles = Profile.order(:full_name)
  end

  def create
    @renewal = Renewal.new(renewal_params)
    
    if @renewal.save
      respond_to do |format|
        format.html do
          flash[:notice] = '续费记录已添加'
          redirect_to admin_renewals_path
        end
      end
    else
      @profiles = Profile.order(:full_name)
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    if @renewal.destroy
      flash[:notice] = '续费记录已删除'
    else
      flash[:alert] = '删除失败'
    end
    
    redirect_to admin_renewals_path(page: params[:page], profile_id: params[:filter_profile_id], search: params[:search])
  end

  private

  def set_renewal
    @renewal = Renewal.find(params[:id])
  end

  def renewal_params
    params.require(:renewal).permit(:profile_id, :payment_date, :amount, :notes)
  end
end
