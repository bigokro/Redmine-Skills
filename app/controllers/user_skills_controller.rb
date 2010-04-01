class UserSkillsController < ApplicationController
  before_filter :load_model
  before_filter :authorize_global

  helper :skills
  include SkillsHelper
  include UserSkillEvaluationsHelper

  def show
     @projects = user_projects
     @user_skill_evaluation = new_user_skill_evaluation_for_form @user
     @user_skill_evaluations = user_skill_evaluations_for_list @user 
  end

  private 
  
  def load_model
    user_id = params[:user_id] || params[:user_skill][:user_id]
    @user = User.find(user_id)
  end
  
  def user_projects
    Project.all.select{|p| p.assignable_users.include? @user}
  end
  
  def authorize_global
    authorize params[:controller], params[:action], :global => true
  end
end