# Matches users to issues based on skill levels and required skills
class SkillsMatcherController < ApplicationController
  unloadable
  
  helper :skills
  include SkillsHelper
  include SkillsMatcherHelper
  helper :sort
  include SortHelper

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
      @matched_issues = available_issues_for(@user) 
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
    @filters = filters_for_issue @issue
    @matched_users = find_users_by_filters @filters
    @matched_users = @matched_users.select{|u| !u.anonymous?}
    refresh_matched_users
  end

  def find_users_by_filter
    create_filters_from_params

    sort_init([['user', 'asc']])
    sort_update(['user'] + @filters.collect{|f| f.skill.name})

    limit = 10
    @user_count = count_users_by_filters @filters
    @user_pages = Paginator.new self, @user_count, limit, params['page']

    @matched_users = find_users_by_filters @filters, @sort_criteria
    @matched_users.reject!{|u| u.anonymous?}

    refresh_matched_users
  end

  def find_issues_by_filter
    create_filters_from_params

    sort_init([['id', 'asc']])
    sort_update(['id', 'issue'] + @filters.collect{|f| f.skill.name})

    limit = 10
    @issue_count = count_issues_by_filters @filters
    @issue_pages = Paginator.new self, @issue_count, limit, params['page']

    # TODO: filter by statuses?
    @matched_issues = find_issues_by_filters @filters, @sort_criteria

    refresh_matched_issues
  end

  private 
  
  def refresh_matched_issues
    respond_to do |format|
      format.html do
          render :template => 'skills_matcher/find_issues', :layout => !request.xhr?
      end
#      format.js do
#        render :update do |page|
#            page.replace_html "content", :partial => "skills_matcher/find_issues"
#        end
#      end
    end
  end

  def refresh_matched_users
    respond_to do |format|
      # TODO: make this redirect parameterizable
      format.html do
        if params[:assign_to_issue]
          render :template => 'required_skills/assign_user'
        else
          render :template => 'skills_matcher/find_users', :layout => !request.xhr?
        end
      end
#      format.js do
#        render :update do |page|
#            page.replace_html "matched_users", :partial => "skills_matcher/find_users"
#        end
#      end
    end
  end
  
  def create_filters_from_params
    @filters = []
    i = 1
    while !params["levels_#{i}"].nil? do
      if params["cb_#{i}"]
        skill = Skill.find_by_name(params["skills_#{i}"])
        @filters << SkillFilter.new(:skill => skill, 
                                    :operator => params["operators_#{i}"],
                                    :level => params["levels_#{i}"].to_i)
      end
      i += 1
    end
  end

end