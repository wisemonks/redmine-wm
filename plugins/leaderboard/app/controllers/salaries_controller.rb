class SalariesController < ApplicationController
  self.main_menu = false

  before_action :require_admin

  def new
    @user = User.find(params[:user_id])
    @salary = Salary.new(user_id: @user.id)
  end

  def create
    @user = User.find(params[:user_id])
    @salary = Salary.new(salary_params)
    @salary.user = @user
    if @salary.save
      flash[:notice] = l(:notice_successful_update)
      redirect_to edit_user_path(@user, tab: 'salaries')
    else
      render :new
    end
  end

  def edit
    @user = User.find(params[:user_id])
    @salary = Salary.find(params[:id])
  end

  def update
    @user = User.find(params[:user_id])
    @salary = Salary.find(params[:id])
    if @salary.update(salary_params)
      flash[:notice] = l(:notice_successful_update)
      redirect_to edit_user_path(@user, tab: 'salaries')
    else
      render :edit
    end
  end

  def destroy
    @user = User.find(params[:user_id])
    @salary = Salary.find(params[:id])
    @salary.destroy
    flash[:notice] = l(:notice_successful_delete)
    redirect_to edit_user_path(@user, tab: 'salaries')
  end

  private

  def salary_params
    params.require(:salary).permit(:salary, :from, :to)
  end
end