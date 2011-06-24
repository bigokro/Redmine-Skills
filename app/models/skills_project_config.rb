class SkillsProjectConfig < ActiveRecord::Base
  # What the system should do when an issue is assigned to a user
  # that has insufficient skills
  UNSKILLED_ACTION_NONE = "none"
  UNSKILLED_ACTION_WARN = "warn"
  UNSKILLED_ACTION_BLOCK = "block"

  belongs_to :project
  
  validates_presence_of :project, :action_on_insufficient_skills
  
  def validate_assignments?
    return action_on_insufficient_skills != UNSKILLED_ACTION_NONE
  end
  
  def block_assignments?
    return action_on_insufficient_skills == UNSKILLED_ACTION_BLOCK
  end
  
  def unskilled_action_options
    SkillsProjectConfig.unskilled_action_options
  end
  
  # Generate a list of all skills used on the project
  def project_skills
    skills = RequiredSkill.find_by_sql(
      ["SELECT DISTINCT rs.skill_id, MAX(rs.level) AS level FROM required_skills rs JOIN issues i ON i.id = rs.issue_id WHERE i.project_id = ? GROUP BY rs.skill_id", project.id])
    skills.sort_by{|rs| rs.skill.name}
  end
  
  def self.unskilled_action_options
    # TODO: regionalize this
    return [["Allow assignment", UNSKILLED_ACTION_NONE], 
            ["Warn", UNSKILLED_ACTION_WARN], 
            ["Block assignment", UNSKILLED_ACTION_BLOCK]]
  end
end
