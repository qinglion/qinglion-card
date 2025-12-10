class Admin::CaseStudiesController < Admin::BaseController
  before_action :set_case_study, only: [:show, :edit, :update, :destroy]

  def index
    @case_studies = CaseStudy.page(params[:page]).per(10)
  end

  def show
  end

  def new
    @case_study = CaseStudy.new
  end

  def create
    @case_study = CaseStudy.new(case_study_params)

    if @case_study.save
      redirect_to admin_case_study_path(@case_study), notice: '案例研究创建成功'
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @case_study.update(case_study_params)
      redirect_to admin_case_study_path(@case_study), notice: '案例研究更新成功'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @case_study.destroy
    redirect_to admin_case_studies_path, notice: '案例研究删除成功'
  end

  private

  def set_case_study
    @case_study = CaseStudy.find(params[:id])
  end

  def case_study_params
    params.require(:case_study).permit(:title, :category, :date, :description, :position, :profile_id)
  end
end
