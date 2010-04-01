require_dependency 'user'
 
# Patches Redmine's Users dynamically. Adds a relationship
# User +has_many+ to UserSkill
# Copied from dvandersluis' redmine_resources plugin: 
# http://github.com/dvandersluis/redmine_resources/blob/master/lib/resources_issue_patch.rb
module UserPatch
  def self.included(base) # :nodoc:
    # Same as typing in the class
    base.class_eval do
      has_many :user_skills, :class_name => 'UserSkill', :foreign_key => 'user_id', :dependent => :delete_all
    end
  end
end
 
User.send(:include, UserPatch)