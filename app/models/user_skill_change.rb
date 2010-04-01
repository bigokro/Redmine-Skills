# A user skill evaluation results in one or more changes to the skill levels
# attributed to a user. Each of these changes is modeled as a UserSkillChange.
# There are four basic types of change that can occur:
# - Promotion: the level for the skill has been increased
# - Demotion: the level for the skill has been lowered
# - New skill: the user has been attributed a skill they previously did not have
# - Skill removed: a skill was removed from the user's list
class UserSkillChange  < ActiveRecord::Base
  TYPE_PROMOTION = "Promotion"
  TYPE_DEMOTION = "Demotion"
  TYPE_ADDITION = "Addition"
  TYPE_DELETION = "Deletion"
  
  belongs_to :user_skill_evaluation
  belongs_to :skill

  validates_presence_of :skill, :old_level, :new_level
  #validates_associated :user_skill_evaluation

  # TODO: validates value of levels btw 0 and 5
  # TODO: validate old != new

  def type
    return TYPE_ADDITION if old_level == 0
    return TYPE_DELETION if new_level == 0
    new_level > old_level ? TYPE_PROMOTION : TYPE_DEMOTION
  end

  def name
    skill.name
  end

  def name= value
    skill = Skill.new if skill.nil?
    skill.name = value
  end
 end