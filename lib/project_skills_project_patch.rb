require_dependency 'project'
 
# Patches Redmine's Projects dynamically. Adds a relationship
# Project +has_many+ ProjectSkill
module ProjectPatch
  def self.included(base) # :nodoc:
    
    # Same as typing in the class
    base.class_eval do
      unloadable # Send unloadable so it will not be unloaded in development
      has_many :project_skills, :class_name => 'ProjectSkill', :foreign_key => 'project_id', :dependent => :delete_all
    end
  end
end
 
Project.send(:include, ProjectPatch)
