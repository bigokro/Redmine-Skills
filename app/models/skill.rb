# A skill is a specific area of knowledge that is required to complete
# a Redmine Issue (task, bug, feature, etc.)
# Skills are identified by their name, which must be globally unique
# (in fact, skills are shared across all projects),
# but they can be organized hierarchically for better grouping and understanding
#
# Skills are linked to Issues via the "RequiredSkills" class. For each skill linked to an issue,
# a minimum required skill level (from 1 (low) to 5 (high)) is declared.
#
# Skills are also associated with users. For each skill that a user has, they are given a skill level
# to indicated their capacity with that skill.
#
# Depending on the project-specific configuration, only users that posses all the required skills
# for an issue, with a capacity of at least the minimum level required, can be assigned to that issue
# (it's also possible to configure a warning instead, or not to interfere with assignment at all).
#
# Note that users implicitly have a starting level of 1 in ALL skills. They may explicitly be given
# a level of 1 for a specific skill for documentation purposes (i.e. they are new with that skill, but
# plan to work with it), but in either case, any user will pass the test for a required skill of level 1.
class Skill  < ActiveRecord::Base
  NAME_MAX_SIZE = 40
  DESCRIPTION_MAX_SIZE = 255

  #has_many :user_skills, :dependent => :destroy
  has_many :required_skills, :dependent => :destroy
  belongs_to :super_skill, :class_name => "Skill"
  has_many :sub_skills, :class_name => "Skill", :foreign_key => "super_skill_id", :dependent => :destroy
  
  validates_presence_of :name, :active
  validates_length_of :name, :maximum => NAME_MAX_SIZE
  validates_length_of :description, :maximum => DESCRIPTION_MAX_SIZE, :allow_nil => true
  validates_uniqueness_of :name

  def self.all_active
    Skill.find_all_by_active(true, :order => "name");
  end
end