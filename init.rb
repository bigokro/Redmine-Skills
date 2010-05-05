require 'dispatcher'
require 'redmine'
require 'required_skills_issue_patch'
require 'show_issue_skills_hook'
require 'update_issue_skills_hook'
require 'user_skills_user_patch'
require 'user_skill_evaluations_user_patch'
require 'show_user_skills_hook'

Dispatcher.to_prepare do
  Issue.send(:include, IssuePatch)
  User.send(:include, UserPatch)
  User.send(:include, UserEvaluationPatch)
end

Redmine::Plugin.register :redmine_skills do
  name 'Skills plugin'
  author 'Timothy High'
  description 'A plugin for Redmine that adds skills and skill levels to issues and users'
  version '0.0.1'

  project_module :skills do
    permission :manage_skills, {
                    :skills => [:new, :edit, :destroy],
                    :skills_project_configs => [:edit],
                    :required_skills => [:add, :remove]
                }
    permission :manage_user_skills, {
                    :user_skills => [:show],
                    :user_skill_evaluations => [:new]
                }
    permission :view_skills, {
                    :skills => [:index, :show ]
                }
    permission :view_own_skills, {
                    :user_skills => [:show]
                }
  end

  menu :top_menu, :skills, { :controller => 'skills', :action => 'index' }, :caption => :label_skills
  menu :project_menu, :skills, { :controller => 'skills_project_configs', :action => 'edit' }, :caption => :label_skills, :param => :id

  default_configs = {}
  IssueStatus.all.each do |status|
    configname = 'assignable_status_' + status.name.gsub(" ", "_").downcase
    default_configs[configname] = status.is_closed ? "0" : "1"
  end
  default_configs['users_can_view_own_skills'] = "1"
  default_configs['view_only_assignable_issues'] = "0"
  settings :default => default_configs, :partial => 'settings/skills'

end
