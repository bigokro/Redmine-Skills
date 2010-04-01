# A required skill is a skill that has been declared as required for a specific issue.
# Required skills are configured with a minimum skill level (from 1 (low) to 5 (high)),
# which indicates the amount of sophistication or depth of knowledge with that skill
# that will be required in order to complete the task/feature/bug/issue.
class RequiredSkill  < ActiveRecord::Base
  belongs_to :issue  
  belongs_to :skill

  validates_presence_of :issue, :skill, :level
  
  def name
    skill.name
  end
end