class UserSkillsController < ApplicationController
  unloadable
  
  before_filter :load_model
  before_filter :authorize_global

  helper :skills
  include SkillsHelper
  include UserSkillEvaluationsHelper

  def index
    @users = users_for_skills_select
  end

  def show
    @issues = user_issues
    @users = users_for_skills_select
    @user_skill_evaluation = new_user_skill_evaluation_for_form @user
    @user_skill_evaluations = user_skill_evaluations_for_list @user 
  end

  private 
  
  def load_model
    user_id = params[:user_id] || params[:user_skill][:user_id] || params[:user][:id]
    @user = User.find(user_id)
  end
  
  def user_issues
    Issue.find_all_by_assigned_to_id(@user.id, :order => :project_id ).reject{|i| i.required_skills.empty?}
  end

  def authorize_global
    authorize params[:controller], params[:action], :global => true
  end
end
