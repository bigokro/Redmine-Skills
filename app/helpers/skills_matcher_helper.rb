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
                       AND rs.skill_id NOT IN (?) 
                       AND 0 < (SELECT COUNT(*) 
                                  FROM required_skills rs 
                                 WHERE i.id = rs.issue_id
                                )
                   )",
                   listable_status_ids,
                   user_skill_ids])
      return matched_issues
  end
  
  def find_available_issues user
      SkillsMatcherHelper.find_available_issues user
  end
  
end

