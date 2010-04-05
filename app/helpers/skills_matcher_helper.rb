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
  
end

