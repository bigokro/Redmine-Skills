class ShowIssueSkillsHook < Redmine::Hook::ViewListener
  render_on :view_issues_show_description_bottom, :partial => "required_skills/required_skills"
end
