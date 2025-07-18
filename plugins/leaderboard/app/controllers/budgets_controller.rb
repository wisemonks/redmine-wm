class BudgetsController < ApplicationController
  before_action :find_project
  before_action :authorize_for_budgets
  before_action :find_budget, only: [:edit, :update, :destroy]

  def index
    @budgets = @project.budgets.order(created_at: :desc)
    @budget = Budget.new
  end

  def new
    @budget = @project.budgets.new
  end

  def create
    @budget = @project.budgets.build(budget_params)
    if @budget.save
      @budgets = @project.budgets.order(created_at: :desc)
      respond_to do |format|
        format.html { redirect_to project_budgets_path(@project), notice: 'Budget created successfully.' }
        format.js
      end
    else
      respond_to do |format|
        format.html { render :new }
        format.js { render :new }
      end
    end
  end

  def edit
  end

  def update
    if @budget.update(budget_params)
      @budgets = @project.budgets.order(created_at: :desc)
      respond_to do |format|
        format.html { redirect_to project_budgets_path(@project), notice: 'Budget updated successfully.' }
        format.js
      end
    else
      respond_to do |format|
        format.html { render :edit }
        format.js { render :edit }
      end
    end
  end

  def destroy
    @budget.destroy
    @budgets = @project.budgets.order(created_at: :desc)
    respond_to do |format|
      format.html { redirect_to project_budgets_path(@project), notice: 'Budget deleted successfully.' }
      format.js
    end
  end

  private

  def budget_params
    params.require(:budget).permit(:budget)
  end

  def find_project
    @project = Project.find(params[:project_id])
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def find_budget
    @budget = @project.budgets.find(params[:id])
  end

  def authorize_for_budgets
    redirect_to home_path unless User.current.mail.in?(['arturas@wisemonks.com', 'rytis@wisemonks.com'])
  end
end
