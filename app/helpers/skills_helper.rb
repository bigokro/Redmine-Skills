module SkillsHelper

  def autotab
    @current_tab ||= 0
    @current_tab += 1
  end

  def skills_top_menu_tabs
    tabs = [{:name => 'skills', :controller => 'skills', :action => :index, :partial => 'skills/list', :label => :label_skills},
            {:name => 'users', :controller => 'user_skills', :action => :index, :partial => 'user_skills/index', :label => :label_user_plural},
            {:name => 'issues', :controller => 'skills_matcher', :action => :find_issues_for_user, :partial => 'skills_matcher/find_issues', :label => :label_issue_plural}
            ]
    tabs.select {|tab| authorize_globally_for(tab[:controller], tab[:action])}     
  end
  
  # Return true if user is authorized for controller/action, regardless of project
  # Otherwise, return false
  def authorize_globally_for(controller, action)
    User.current.allowed_to?({:controller => controller, :action => action}, nil, :global => true)
  end

  # Display a link if user is authorized for this global action
  def link_to_if_globally_authorized(name, options = {}, html_options = nil, *parameters_for_method_reference)
    link_to(name, options, html_options, *parameters_for_method_reference) if authorize_globally_for(options[:controller] || params[:controller], options[:action])
  end

  # Display a link to remote if user is authorized for this global action
  def link_to_remote_if_globally_authorized(name, options = {}, html_options = nil)
    url = options[:url] || {}
    link_to_remote(name, options, html_options) if authorize_globally_for(url[:controller] || params[:controller], url[:action])
  end

  def autocomplete_skills_for element_id, options_element_id = "#{element_id}_autocomplete"
    active_skills = Skill.all_active
    if active_skills
      <<-eos
        #{stylesheet_link_tag 'autocomplete', :plugin => 'redmine_skills'}
        <script>
          document.observe("dom:loaded", function() {
            var data = "#{active_skills.collect{|s| s.name}.join(',')}".split(",");
            new Autocompleter.Local("#{element_id}", "#{options_element_id}", data, {partialChars: 2, choices: 20});
          });
        </script>
      eos
    else
      ""
    end
  end

end

