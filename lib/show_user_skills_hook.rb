class ShowUserSkillsHook < Redmine::Hook::ViewListener
  render_on :view_account_left_bottom, :partial => "user_skills/user_skills"
  render_on :view_my_account, :partial => "user_skills/user_skills"
end
