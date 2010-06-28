class UserSkillEvaluationsController < ApplicationController
  unloadable
  
  before_filter :authorize_global

  helper :skills
  include SkillsHelper
  include UserSkillEvaluationsHelper

  def new
    @user_skill_evaluation = UserSkillEvaluation.new(params[:user_skill_evaluation])
    @user_skill_evaluation.evaluator_id = User.current.id
    @user_skill_evaluation.evaluator = User.current
    @user = User.find(params[:user_skill_evaluation][:user_id].to_i)
    if request.post?
      handle_new_skills
      @user_skill_evaluation.user_skill_changes.delete_if{|c| c.skill_id.nil?} 
      if @user_skill_evaluation.save
        flash[:notice] = l(:notice_successful_create)
      end
    end
    refresh_user_skills
  end

  private 
  
  def refresh_user_skills
    @user.reload
    @user_skill_evaluation = new_user_skill_evaluation_for_form @user
    @user_skill_evaluations = user_skill_evaluations_for_list @user 
    respond_to do |format|
      format.js do
        render :update do |page|
            page.replace_html "user_skills", :partial => "user_skills/user_skills_form"
        end
      end
    end
  end

  def authorize_global
    authorize params[:controller], params[:action], :global => true
  end
  
  # Checks to see if one or more "write-in" skills have been added to the evaluation
  # For each entry, there are the following possibilities:
  # 1. No new skill (a level will be submitted, but with no accompanying name) (removed in the calling method)
  # 2. New skill not in user's list, but already in the system (add to user)
  # 3. "New" skill, but already in the user's list (reject) (currently not dealt with)
  # 4. New skill to both user and system (add to system and user)
  def handle_new_skills
      index_key = (-params[:user_skill_evaluation][:new_user_skill_change_attributes].length + 1).to_s
      @user_skill_evaluation.user_skill_changes.select{|c| c.skill_id.nil?}.each do |new_change|
        name = params[:user_skill_evaluation][:new_user_skill_change_attributes][index_key][:name]
        level = params[:user_skill_evaluation][:new_user_skill_change_attributes][index_key][:new_level].to_i
        unless name.nil?
          skill = Skill.find_by_name(name)
          if skill.nil?
            skill = Skill.new(:name => name, :active => true)
            skill.save
          end
          new_change.skill_id = skill.id
          new_change.new_level = level
        end
        index_key = (index_key.to_i + 1).to_s
      end
  end
end
