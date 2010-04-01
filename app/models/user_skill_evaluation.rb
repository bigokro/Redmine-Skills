# A user's skills are not managed like other types of data, where it changes and that's that.
# It is important to audit the history of these changes, provide notifications of them,
# and also link to concrete examples that show a user's prowess as a form of justification
# for their ratings.
# This is done by recording each change as an "evaluation" of their skills. And evaluation
# can result in the promotion and/or demotion of any number of skills to different levels
# from 0 (removal) to 5 (expert). The evaluation consists of the changes in skills levels,
# plus an explanation of the evaluation, and an optional link to a Redmine issue that
# led to or exemplifies the new evaluation. 
class UserSkillEvaluation  < ActiveRecord::Base
  after_save :save_changes
  after_update :save_changes

  belongs_to :user
  belongs_to :issue
  belongs_to :evaluator, :class_name =>"User"
  has_many :user_skill_changes  #, :inverse_of => :user_skill_evaluation

  validates_presence_of :user, :evaluator
  #validates_associated :user_skill_changes
  # TODO: can user evaluate oneself?
  
  def new_user_skill_change_attributes=(change_attributes)
    change_attributes.each do |attributes|
      # ID may be set to a temporary value in the form
      #raise attributes.inspect
      values = attributes[1]
      if values['old_level'] != values['new_level']
         user_skill_changes.build(values)
      end
    end 
  end

  def existing_user_skill_change_attributes=(change_attributes)
    user_skill_changes.reject(&:new_record?).each do |change|
      attributes = change_attributes[change.id.to_s]
      change.attributes = attributes
    end
  end

  private

  def save_changes
#    raise user_skill_changes.inspect
    user_skill_changes.each do |change|
#      raise change.inspect
      user_skills = user.user_skills.select{|us| us.skill == change.skill}
      if (user_skills.length > 0)
        user_skill = user_skills[0]
        if change.type == UserSkillChange::TYPE_DELETION
          user_skill.destroy
        else
          user_skill.level = change.new_level
          user_skill.save
        end
      else
        new_skill = UserSkill.new
        new_skill.level = change.new_level
        new_skill.skill = change.skill
        new_skill.user = user
        user.user_skills << new_skill
        new_skill.save
        user.save
      end
    end
  end

 end