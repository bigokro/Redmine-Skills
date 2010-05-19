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
  
  def test_filter_users_one_user_one_filter_no_excludes
    user = sample_user
    filters = [SkillFilter.new(:skill => user.user_skills[0].skill,
                                :operator => ">=",
                                :level => user.user_skills[0].level)]
    filtered_users = SkillsMatcherHelper.filter_users [user], filters
    assert_equal 1, filtered_users.size
    assert_equal user, filtered_users[0]
  end
  
  def test_filter_users_one_user_one_filter_excluded
    user = sample_user
    filters = [SkillFilter.new(:skill => user.user_skills[0].skill,
                                :operator => ">=",
                                :level => user.user_skills[0].level + 1)]
    filtered_users = SkillsMatcherHelper.filter_users [user], filters
    assert_true filtered_users.empty?
  end
  
  def test_filter_users_one_user_multiple_filters_no_excludes
    user = sample_user
    filters = SkillsMatcherHelper.filters_for_user user
    # A user should match their own filter
    filtered_users = SkillsMatcherHelper.filter_users [user], filters
    assert_equal 1, filtered_users.size
    assert_equal user, filtered_users[0]
  end

  def test_filter_users_multiple_users_multiple_filters
    user = sample_user
    user2 = sample_user
    user3 = sample_user
    user.user_skills[0].level -= 1
    user2.user_skills[1].level += 1
    user3.user_skills[2].level += 1
    filters = SkillsMatcherHelper.filters_for_user user
    filtered_users = SkillsMatcherHelper.filter_users [user, user2, user3], filters
    assert_equal 1, filtered_users.size
    assert_equal user, filtered_users[0]
  end

  def test_filter_users_more_filters_than_skills
    user = sample_user
    filters = SkillsMatcherHelper.filters_for_user user
    filters.each{ |f| f.operator = ">=" }
    user.user_skills.delete_at(2)
    filtered_users = SkillsMatcherHelper.filter_users [user], filters
    assert_true filtered_users.empty?
  end

  def test_filter_trivial_filter
    user = sample_user
    skill = user.user_skills.select{|us| us.skill.name == "Java"}[0].skill
    filters = [ SkillFilter.new(:skill => skill, :operator => ">=", :level => 1)]
    filtered_users = SkillsMatcherHelper.filter_users [user], filters
    assert_equal 1, filtered_users.size
    assert_equal user, filtered_users[0]
  end

  def test_filter_none
    user = sample_user
    user2 = sample_user
    skill = user.user_skills[0].skill
    user.user_skills.delete_at(0)
    filters = [ SkillFilter.new(:skill => skill, :operator => "!*")]
    filtered_users = SkillsMatcherHelper.filter_users [user, user2], filters
    assert_equal 1, filtered_users.size
    assert_equal user, filtered_users[0]
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
  
  def sample_user
    user = User.new
    user.login = "testuser"
    unless @test_skills
      @test_skills = [
        Skill.new(:name => "Java"),
        Skill.new(:name => "Rails"),
        Skill.new(:name => "jQuery")
      ]
    end
    user.user_skills = @test_skills.collect do |s|
      UserSkill.new(:user => user, :level => 3, :skill => s)
    end
    return user
  end
end
