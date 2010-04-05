require File.dirname(__FILE__) + '/../test_helper'
require 'action_view/test_case'

# TODO: Make this faster by doing only in-memory tests? 
class SkillsMatcherHelperTest < ActionView::TestCase
  fixtures :skills,
            :issues,
            :users
  
  def setup
    @skill = skills(:valid)
    @user = users(:users_001)
    @issue = issues(:issues_001)
  end

  def test_user_is_qualified_no_requirements
    assert_true user_is_qualified?(@user, @issue)
  end
  
  def test_user_is_qualified_equal
    add_skill 4, 4
    assert_true user_is_qualified?(@user, @issue)
  end
  
  def test_user_is_qualified_more
    add_skill 4, 3
    assert_true user_is_qualified?(@user, @issue)
  end
  
  def test_user_is_qualified_less
    add_skill 3, 4
    assert_false user_is_qualified?(@user, @issue)
  end
  
  def test_user_is_qualified_trivial_requirement
    add_skill 0, 1
    assert_true user_is_qualified?(@user, @issue)
  end
  
  def test_user_is_qualified_missing_skill
    add_skill 0, 3
    assert_false user_is_qualified?(@user, @issue)
  end
  
  def test_user_is_qualified_two_skills
    add_skill 4, 3
    add_skill 4, 4, skills(:valid_name_max_length)
    assert_true user_is_qualified?(@user, @issue)
  end

  def test_user_is_qualified_two_skills_one_trivial
    add_skill 4, 3
    add_skill 0, 1, skills(:valid_name_max_length)
    assert_true user_is_qualified?(@user, @issue)
  end

  def test_user_is_qualified_two_skills_one_too_low
    add_skill 4, 3
    add_skill 2, 5, skills(:valid_name_max_length)
    assert_false user_is_qualified?(@user, @issue)
  end

  def test_user_is_qualified_two_skills_one_missing
    add_skill 4, 3
    add_skill 0, 2, skills(:valid_name_max_length)
    assert_false user_is_qualified?(@user, @issue)
  end
  
  def test_user_is_qualified_two_skills_one_required
    add_skill 4, 3
    add_skill 3, 0, skills(:valid_name_max_length)
    assert_true user_is_qualified?(@user, @issue)
  end
  
private
  
  def add_skill ulevel, ilevel, skill = @skill, user = @user, issue = @issue
    unless user.nil? || ulevel <= 0
      uskill = UserSkill.new :user => user, :skill => skill, :level => ulevel
      user.user_skills << uskill
      user.save
    end
    unless issue.nil? || ilevel <= 0
      rskill = RequiredSkill.new :issue => issue, :skill => skill, :level => ilevel
      issue.required_skills << rskill
      issue.save
    end
  end
end
