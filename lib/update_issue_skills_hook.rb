module ValidateAssigneeQualifications
  include SkillsMatcherHelper
  def validate
    unless assigned_to.nil? || user_is_qualified?(assigned_to, self)
      errors.add_to_base I18n.t(:error_assignee_unqualified)
    end
    super
  end
end

class UpdateIssueSkillsHook < Redmine::Hook::Listener
  include SkillsMatcherHelper
  
  def controller_issues_edit_before_save(context={})
    # Extend the issue to include the module defined above
    # The hook unfortunately doesn't provide an easy way to prevent the issue from saving
    # and redefining the validate() method on Issue using an alias results in an infinite loop
    # See http://blog.jayfields.com/2008/04/alternatives-for-redefining-methods.html
    issue = context[:issue]
    issue.extend(ValidateAssigneeQualifications)
  end
end
