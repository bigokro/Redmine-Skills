# Part of the project configurations
# Skills recorded in this way will automatically be added as required skills to any
# new Work Item created for the project
# TODO: Associate with issue types
class ProjectSkill  < ActiveRecord::Base
  belongs_to :project
  belongs_to :skill

  validates_presence_of :project, :skill, :level
  
  def name
    skill.name
  end
end
