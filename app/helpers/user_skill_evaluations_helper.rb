module UserSkillEvaluationsHelper

  def new_user_skill_evaluation_for_form user
     user_skill_evaluation = UserSkillEvaluation.new
     i = -1
     user.user_skills.sort_by{|c| c.skill.name}.each do |us|
       change = UserSkillChange.new
       change.skill = us.skill
       change.old_level = us.level
       change.new_level = us.level
       change.id = i
       i -= 1
       user_skill_evaluation.user_skill_changes << change
   end
   return user_skill_evaluation
  end
 
  def user_skill_evaluations_for_list user
    UserSkillEvaluation.find_all_by_user_id(user.id, :include => :evaluator, :order => 'created_on DESC')
  end

end

