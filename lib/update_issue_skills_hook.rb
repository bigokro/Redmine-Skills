class Issue
  include SkillsMatcherHelper

  def action_for_assignee
    if assigned_to.nil? || user_is_qualified?(assigned_to, self)
      :allow
    else
      config = SkillsProjectConfig.find_by_project_id(project_id)
      if !config.nil? && config.validate_assignments?
        if config.block_assignments?
          :block
        else
          :warn
        end
      else
        :allow
      end
    end
  end

  protected

  def validate_on_update
    if action_for_assignee == :block
      errors.add_to_base I18n.t(:error_assignee_unqualified)
    end
    super
  end

end

class IssuesController < ApplicationController
  after_filter :warn_unqualified, :only => :edit

  private

  def warn_unqualified
    if request.post? && @issue.action_for_assignee == :warn
      flash[:error] = l(:text_unqualified_assignee_warn)
    end
  end

end


class UpdateIssueSkillsHook < Redmine::Hook::Listener
   
  def controller_issues_new_after_save(context={})
    issue = context[:issue]
    project = issue.project
    project.project_skills.each do |ps|
      required_skill = RequiredSkill.new(:issue => issue, :skill => ps.skill, :level => ps.level)
      required_skill.save
    end
  end
  
end
