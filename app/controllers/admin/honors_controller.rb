class Admin::HonorsController < Admin::BaseController
  before_action :set_honor, only: [:show, :edit, :update, :destroy]

  def index
    @honors = Honor.page(params[:page]).per(10)
  end

  def show
  end

  def new
    @honor = Honor.new
  end

  def create
    @honor = Honor.new(honor_params)

    if @honor.save
      redirect_to admin_honor_path(@honor), notice: '荣誉奖项创建成功'
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @honor.update(honor_params)
      redirect_to admin_honor_path(@honor), notice: '荣誉奖项更新成功'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @honor.destroy
    redirect_to admin_honors_path, notice: '荣誉奖项删除成功'
  end

  private

  def set_honor
    @honor = Honor.find(params[:id])
  end

  def honor_params
    params.require(:honor).permit(:title, :organization, :date, :description, :icon_name, :profile_id)
  end
end
