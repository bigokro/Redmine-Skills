module SkillsMatcherHelper

  def user_is_qualified? user, issue
    if issue.required_skills.nil?
      true
    else
      issue.required_skills.each do |rs|
        # TODO: optional configuration for validating even trivial skills
        # TODO: ignore inactive skills?
        # TODO: allow user to qualify with related (parent/child) skills?
        if rs.level > 1
          return false if user.user_skills.nil?
          uskills = user.user_skills.select{|us| us.skill == rs.skill}
          return false if uskills.nil? || uskills.length == 0 || uskills[0].level < rs.level        
        end
      end
    end
    true
  end

  def available_issues_for user
      SkillsMatcherHelper.find_available_issues(user)
  end
  
  def find_users_by_filters filters, sort_criteria = nil, count_only = false
    ordered = filters.sort{ |a,b| b.rarity <=> a.rarity }
    condition = "1 = 1"
    unless filters.empty?
      condition = ordered[0].where_condition "us"
    end
    if count_only
      User.count_by_sql(["
        SELECT COUNT(DISTINCT u.id)
          FROM users u, user_skills us
         WHERE u.id = us.user_id
           AND #{condition}
              "])
    else
      users = User.find_by_sql(["
        SELECT DISTINCT u.id
          FROM users u, user_skills us
         WHERE u.id = us.user_id
           AND #{condition}
              "])
      users = users.collect{|u| User.find_by_id(u.id)}
      users = SkillsMatcherHelper.filter_users users, filters
      return sort_users_by_criteria users, sort_criteria
    end
  end
  
  def count_users_by_filters filters
    find_users_by_filters filters, nil, true
  end

  
  def find_issues_by_filters filters, sort_criteria = nil, count_only = false
    return SkillsMatcherHelper.find_issues_by_filters filters, sort_criteria, count_only
  end

  def self.find_issues_by_filters filters, sort_criteria = nil, count_only = false
    return [] if filters.empty?
    skill_ids = filters.reject{|f| f.skill.nil?}.collect{|f| f.skill.id}
    listable_status_ids = IssueStatus.all.collect{ |s| Setting['plugin_redmine_skills']['assignable_status_' + s.name.gsub(" ", "_").downcase] == "1" ? s.id : nil}.compact
    assignable_projects_condition = ''
#      if Setting['plugin_redmine_skills']['view_only_assignable_issues'] == "1"
#        project_ids = Project.all.collect{ |p| p.assignable_users.include?(user) ? p.id : nil }.compact
#        project_ids << 0 # the case of a user assignable to no projects
#        assignable_projects_condition = "AND project_id IN (#{project_ids.join(',')})"
#      end
    ordered = filters.sort{ |a,b| b.rarity <=> a.rarity }
    condition = ""
    if !ordered.empty? && ordered[0].kind_of?(NoOtherSkillsFilter)
      condition = "AND " + ordered[0].where_condition("rs")
    end
    if count_only
      Issue.count_by_sql(["
        SELECT COUNT(DISTINCT i.id)
          FROM issues i
          LEFT JOIN required_skills rs ON i.id = rs.issue_id
         WHERE status_id IN (?)
           #{condition}
           #{assignable_projects_condition}
           -- Only issues with at least one rs are considered assignable
           AND 0 < (SELECT COUNT(*) 
                      FROM required_skills rs2
                     WHERE i.id = rs2.issue_id
                       AND rs2.skill_id IN (?)
              )",
              listable_status_ids,
              skill_ids])
    else
      issues = Issue.find_by_sql(["
        SELECT DISTINCT i.id
          FROM issues i
          LEFT JOIN required_skills rs ON i.id = rs.issue_id
         WHERE status_id IN (?)
           #{condition}
           #{assignable_projects_condition}
           -- Only issues with at least one rs are considered assignable
           AND 0 < (SELECT COUNT(*) 
                      FROM required_skills rs2
                     WHERE i.id = rs2.issue_id
                       AND rs2.skill_id IN (?)
              )",
              listable_status_ids,
              skill_ids])
      issues = issues.collect{|i| Issue.find_by_id(i.id)}
      issues = SkillsMatcherHelper.filter_issues issues, filters
      return sort_issues_by_criteria issues, sort_criteria
    end
  end
  
  def count_issues_by_filters filters
    find_issues_by_filters filters, nil, true
  end

  
  
  
  # Pulls a list of issues out of the database for which the user is qualified
  # The initial list is generated from the database based on the user's skills (but not levels)
  # This is then passed through a finer filter (in memory) using the Skill Filters
  def self.find_available_issues user
#      user_skill_ids = user.user_skills.collect{|us| us.skill_id}
#      listable_status_ids = IssueStatus.all.collect{ |s| Setting['plugin_redmine_skills']['assignable_status_' + s.name.gsub(" ", "_").downcase] == "1" ? s.id : nil}.compact
#      assignable_projects_condition = ''
#      if Setting['plugin_redmine_skills']['view_only_assignable_issues'] == "1"
#        project_ids = Project.all.collect{ |p| p.assignable_users.include?(user) ? p.id : nil }.compact
#        project_ids << 0 # the case of a user assignable to no projects
#        assignable_projects_condition = "AND project_id IN (#{project_ids.join(',')})"
#      end
#      matched_issues = Issue.find_by_sql(["
#        SELECT * 
#          FROM issues i 
#         WHERE status_id IN (?)
#           #{assignable_projects_condition}
#           AND 0 = (SELECT COUNT(*)
#                      FROM required_skills rs 
#                     WHERE i.id = rs.issue_id 
#                       AND rs.level > 1 
#                       AND rs.skill_id NOT IN (?))
#           -- Only issues with at least one rs are considered assignable
#           AND 0 < (SELECT COUNT(*) 
#                      FROM required_skills rs2 
#                     WHERE i.id = rs2.issue_id
#                   )",
#                   listable_status_ids,
#                   user_skill_ids])
#      return filter_issues(matched_issues, filters_for_user(user))
    matched_issues = find_issues_by_filters filters_for_user(user)
  end
  
  # Removes users from a list based on an array of SkillFilters
  def self.filter_users users, filters
    users.select{ |u| filters.select{|f| f.excludes? u.user_skills }.empty? }
  end
  
  # Removes issues from a list based on an array of SkillFilters
  def self.filter_issues issues, filters
    issues.select{ |i| filters.select{|f| f.excludes? (i.required_skills, false) }.empty? }
  end
  
  # Returns an array of SkillFilters based on the required skills
  # Uses the operator ">=" for each
  # If the skill level is 1 and the plugin is configured for "implicit levels" of 1,
  # then that skill does not generate a filter
  # TODO: implement the implicit levels config
  def self.filters_for_issue issue
    filters = issue.required_skills.collect do |rs|
      f = SkillFilter.new
      f.skill = rs.skill
      f.level = rs.level
      f.operator = ">="
      f
    end
    filters = filters.compact
    relevant_filters = filters.select{|f| f.level > 1}
    relevant_filters.empty? ? filters : relevant_filters
  end

  def filters_for_issue issue
    SkillsMatcherHelper.filters_for_issue issue
  end

  # Returns an array of SkillFilters based on a user's skills
  # Uses the operator "<=" for each
  # TODO: implement filter for "no other skills (required)"
  def self.filters_for_user user
    return [] if user.user_skills.empty?
    filters = user.user_skills.collect do |rs|
        f = SkillFilter.new
        f.skill = rs.skill
        f.level = rs.level
        f.operator = "<="
        f
    end
    no_others = NoOtherSkillsFilter.new
    no_others.filters = filters
    filters << no_others
  end

  def filters_for_user user
    SkillsMatcherHelper.filters_for_user user
  end
  
  private

  # See sort_helper.rb for more information on the SortCriteria class
  def sort_users_by_criteria users, sort_criteria
    return users if sort_criteria.nil? || sort_criteria.empty?
    sorted_users = users
    sort_criteria.to_param.split(',').reverse.each do |c|
      field = c.split(':')[0]
      if field == "user"
        sorted_users.sort!{|x,y| x.login <=> y.login}
      else
        sorted_users.sort! do |x,y|
          x_user_skill = x.user_skills.select{|us| us.skill.name == field}[0]
          y_user_skill = y.user_skills.select{|us| us.skill.name == field}[0]
          x_user_skill.level <=> y_user_skill.level
        end
      end
      sorted_users.reverse! if c.ends_with?(":desc")
    end
    return sorted_users
  end

  # See sort_helper.rb for more information on the SortCriteria class
  def self.sort_issues_by_criteria issues, sort_criteria
    return issues if sort_criteria.nil? || sort_criteria.empty?
    sorted_issues = issues
    sort_criteria.to_param.split(',').reverse.each do |c|
      field = c.split(':')[0]
      if ["id", "subject", "project.name", "tracker.name", "status"].include? field
        sorted_issues.sort!{|x,y| eval("x.#{field}") <=> eval("y.#{field}")}
      else
        sorted_issues.sort! do |x,y|
          x_required_skill = x.required_skills.select{|us| us.skill.name == field}[0]
          y_required_skill = y.required_skills.select{|us| us.skill.name == field}[0]
          x_level = x_required_skill.nil? ? -1 : x_required_skill.level
          y_level = y_required_skill.nil? ? -1 : y_required_skill.level
          x_level <=> y_level
        end
      end
      sorted_issues.reverse! if c.ends_with?(":desc")
    end
    return sorted_issues
  end

end

