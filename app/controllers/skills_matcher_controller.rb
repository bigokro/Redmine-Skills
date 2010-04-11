# Matches users to issues based on skill levels and required skills
class SkillsMatcherController < ApplicationController
  unloadable
  
  helper :skills
  include SkillsHelper
  include SkillsMatcherHelper

  def find_issues_for_user
    if request.post?
      @user = User.find(params[:user_id])
      # Types of search:
      # - include issues with no requirements?
      # - explicit filter (vs. user-based)
      # - Limit to one project
      # note: this is a little harder, since you are looking for the inverse:
      # issues that don't require things you aren't qualified to do
      # TODO: handle hierarchical skill relationships
      # TODO: allow configuration of handling of trivial skill level requirements
      # TODO: filter for status, already assigned
      user_skill_ids = @user.user_skills.collect{|us| us.skill_id}
      @matched_issues = Issue.find_by_sql(['SELECT * FROM issues i WHERE 0 = (SELECT COUNT(*) FROM required_skills rs WHERE i.id = rs.issue_id AND rs.level > 1 AND rs.skill_id NOT IN (?))', user_skill_ids]) 
      refresh_matched_issues
    else
      @user = User.current
    end
  end
  
  def find_users_for_issue
    @issue = Issue.find(params[:issue_id])
    # Get initial list based on the highest-level required skill
    # Future optimizations can use nested selects
    # e.g. SELECT user_id FROM user_skills WHERE skill_id = #{skill1.id} AND level >= #{skill1.level}
    #         AND user_id IN ( SELECT user_id FROM user_skills WHERE skill_id = #{skill2.id} AND level >= #{skill2.level})

    # Future filters:
    # - Limit to assignable users
    # - Explicit filter
    # - Include users that *could* be eligible if they were promoted by one
    # TODO: handle hierarchical skill relationships
    # TODO: allow configuration of handling of trivial skill level requirements
    rskills = @issue.required_skills.select{|rs| rs.level > 1}
    if rskills.nil? || rskills.length == 0
      # TODO: what about inactive users?
      @matched_users = User.all
    else
      @matched_users = []
      rskill = rskills.sort{|x,y| y.level <=> x.level}[0]
      user_skills = UserSkill.find(:all, :conditions => "skill_id = #{rskill.skill_id} AND level >= #{rskill.level}")
      if !user_skills.nil?
        user_skills.each do |us|
          if user_is_qualified? us.user, @issue
            @matched_users << us.user
          end
        end
      end
    end
    refresh_matched_users
  end
  
  private 
  
  def refresh_matched_issues
    respond_to do |format|
      format.js do
        render :update do |page|
            page.replace_html "matched_issues", :partial => "skills_matcher/find_issues"
        end
      end
    end
  end

  def refresh_matched_users
    respond_to do |format|
      format.html { render :template => 'skills_matcher/assign_user' }
      format.js do
        render :update do |page|
            page.replace_html "matched_users", :partial => "skills_matcher/find_users"
        end
      end
    end
  end

end