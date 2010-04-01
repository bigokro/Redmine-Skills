require_dependency 'user'
 
# Patches Redmine's Users dynamically. Adds a relationship
# User +has_many+ to UserSkillEvaluation
# Copied from dvandersluis' redmine_resources plugin: 
# http://github.com/dvandersluis/redmine_resources/blob/master/lib/resources_issue_patch.rb
module UserEvaluationPatch
  def self.included(base) # :nodoc:
    # Same as typing in the class
    base.class_eval do
      has_many :user_skill_evaluations, 
                :class_name => 'UserSkillEvaluation', 
                :foreign_key => 'user_id', 
                :dependent => :delete_all, 
                :order => 'created_on DESC' 
    end
  end
end
 
User.send(:include, UserEvaluationPatch)