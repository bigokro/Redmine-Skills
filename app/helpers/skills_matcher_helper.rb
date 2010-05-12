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
  
  def find_users_by_filters filters
    ordered = filters.sort{ |a,b| b.rarity <=> a.rarity }
    condition = "1 = 1"
    unless filters.empty?
      condition = ordered[0].where_condition "us"
    end
    users = User.find_by_sql(["
      SELECT DISTINCT u.id
        FROM users u, user_skills us
       WHERE u.id = us.user_id
         AND #{condition}
            "])
    users = users.collect{|u| User.find_by_id(u.id)}
    return SkillsMatcherHelper.filter_users users, filters
  end
  
  def find_issues_by_filters filters
    ordered = filters.sort{ |a,b| b.rarity <=> a.rarity }
    condition = "1 = 1"
    unless filters.empty?
      condition = ordered[0].where_condition "rs"
    end
    issues = User.find_by_sql(["
      SELECT *
        FROM issues i
        LEFT JOIN required_skills rs ON u.id = rs.issue_id
       WHERE #{condition}
         -- Only issues with at least one rs are considered assignable
         AND 0 < (SELECT COUNT(*) 
                    FROM required_skills rs2
                   WHERE i.id = rs2.issue_id
            )"])
    return SkillsMatcherHelper.filter_issues issues, filters
  end
  
  # Pulls a list of issues out of the database for which the user is qualified
  # The initial list is generated from the database based on the user's skills (but not levels)
  # This is then passed through a finer filter (in memory) using the Skill Filters
  def self.find_available_issues user
      user_skill_ids = user.user_skills.collect{|us| us.skill_id}
      listable_status_ids = IssueStatus.all.collect{ |s| Setting['plugin_redmine_skills']['assignable_status_' + s.name.gsub(" ", "_").downcase] == "1" ? s.id : nil}.compact
      assignable_projects_condition = ''
      if Setting['plugin_redmine_skills']['view_only_assignable_issues'] == "1"
        project_ids = Project.all.collect{ |p| p.assignable_users.include?(user) ? p.id : nil }.compact
        project_ids << 0 # the case of a user assignable to no projects
        assignable_projects_condition = "AND project_id IN (#{project_ids.join(',')})"
      end
      matched_issues = Issue.find_by_sql(["
        SELECT * 
          FROM issues i 
         WHERE status_id IN (?)
           #{assignable_projects_condition}
           AND 0 = (SELECT COUNT(*)
                      FROM required_skills rs 
                     WHERE i.id = rs.issue_id 
                       AND rs.level > 1 
                       AND rs.skill_id NOT IN (?))
           -- Only issues with at least one rs are considered assignable
           AND 0 < (SELECT COUNT(*) 
                      FROM required_skills rs2 
                     WHERE i.id = rs2.issue_id
                   )",
                   listable_status_ids,
                   user_skill_ids])
      return filter_issues(matched_issues, filters_for_user(user))
  end
  
  # Removes users from a list based on an array of SkillFilters
  def self.filter_users users, filters
    users.select{ |u| !u.user_skills.empty? && u.user_skills.select{ |us| filters.select{|f| f.excludes? us}.size > 0 }.empty? }
  end
  
  # Removes issues from a list based on an array of SkillFilters
  def self.filter_issues issues, filters
    issues.select{ |i| i.required_skills.select{ |rs| filters.select{|f| f.excludes? rs}.size > 0 }.empty? }
  end
  
  # Returns an array of SkillFilters based on the required skills
  # Uses the operator ">=" for each
  # If the skill level is 1 and the plugin is configured for "implicit levels" of 1,
  # then that skill does not generate a filter
  # TODO: implement the implicit levels config
  def self.filters_for_issue issue
    filters = issue.required_skills.collect do |rs|
      unless rs.level == 1
        f = SkillFilter.new
        f.skill = rs.skill
        f.level = rs.level
        f.operator = ">="
        f
      end
    end
    filters.compact
  end

  def filters_for_issue issue
    SkillsMatcherHelper.filters_for_issue issue
  end

  # Returns an array of SkillFilters based on a user's skills
  # Uses the operator "<=" for each
  # TODO: implement filter for "no other skills (required)"
  def self.filters_for_user user
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

end

