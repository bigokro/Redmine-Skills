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


#class UpdateIssueSkillsHook < Redmine::Hook::Listener
#  include SkillsMatcherHelper
#  
#  def controller_issues_edit_before_save(context={})
#    # Extend the issue to include the module defined above
#    # The hook unfortunately doesn't provide an easy way to prevent the issue from saving
#    # and redefining the validate() method on Issue using an alias results in an infinite loop
#    # See http://blog.jayfields.com/2008/04/alternatives-for-redefining-methods.html
#    issue = context[:issue]
#    issue.extend(ValidateAssigneeQualifications)
#  end
#  
#end
