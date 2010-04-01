# A user skill is a skill that a user has shown some proficiency in, or has used to work on an issue.
# Just as required skills (for issues) are configured with a minimum skill level 
# (from 1 (low) to 5 (high)), so too are the skill levels of users. 
# All users have an implicit skill level of 1 in all skills. This may be made explicit in the
# case that a user is assigned an issue that requires that skill (at level 1).
# In order to gain a higher skill rating, they must show proficiency through their work
# such that a technical manager feels justified in approving them for more advanced work.
class UserSkill  < ActiveRecord::Base
  belongs_to :user
  belongs_to :skill

  validates_presence_of :user, :skill, :level
  
  def name
    skill.name
  end
end