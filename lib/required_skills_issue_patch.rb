require_dependency 'issue'
 
# Patches Redmine's Issues dynamically. Adds a relationship
# Issue +has_many+ to RequiredSkill
# Copied from dvandersluis' redmine_resources plugin: 
# http://github.com/dvandersluis/redmine_resources/blob/master/lib/resources_issue_patch.rb
module IssuePatch
  def self.included(base) # :nodoc:
    
    # Same as typing in the class
    base.class_eval do
#      unloadable # Send unloadable so it will not be unloaded in development
      has_many :required_skills, :class_name => 'RequiredSkill', :foreign_key => 'issue_id', :dependent => :delete_all
    end
  end
end
 
Issue.send(:include, IssuePatch)