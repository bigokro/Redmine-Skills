require File.dirname(__FILE__) + '/../test_helper'

class SkillTest < ActiveSupport::TestCase
  fixtures :skills
  
  def setup
    @valid_skill = skills(:valid)
  end

  # This Skill should be valid by construction.
  def test_validity
    assert @valid_skill.valid?
  end

  def test_description_nil
    @valid_skill.description = nil
    assert @valid_skill.valid?
  end

  def test_name_max_length
    valid_name_max_length = skills(:valid_name_max_length)
    assert valid_name_max_length.valid?
  end

  def test_name_max_length_plus_one
    valid_skill = skills(:valid_name_max_length)
    invalid_skill = valid_skill.clone
    invalid_skill.name += "a"
    invalid_skill.description += "a"
    assert !invalid_skill.save
    fields = [:name, :description]
    lengths = [Skill::NAME_MAX_SIZE, Skill::DESCRIPTION_MAX_SIZE]
    assert_fields_max_length_enforced(invalid_skill, fields, lengths)
  end
  
  def test_required_fields
    invalid_skill = @valid_skill.clone
    invalid_skill.name = nil
    invalid_skill.active = nil
    assert !invalid_skill.save
    fields = [:name, :active]
    assert_required_fields_enforced(invalid_skill, fields)
  end
  
  def test_destroy
    id = @valid_skill.id
    Skill.find(id).destroy
    assert_nil Skill.find_by_id(id)
  end

  def test_sub_skills
    sub_skill = skills(:sub_skill)
    assert_equal @valid_skill, sub_skill.super_skill
    assert_equal 1, @valid_skill.sub_skills.size
    assert_equal sub_skill, @valid_skill.sub_skills[0]
  end

  def test_add_sub_skills
    newsub = skills(:valid_name_max_length)
    assert_nil newsub.super_skill
    assert_equal 1, @valid_skill.sub_skills.size
    @valid_skill.sub_skills << newsub
    @valid_skill.save!
    assert_equal @valid_skill, newsub.super_skill
    assert_equal 2, @valid_skill.sub_skills.size
    assert_true @valid_skill.sub_skills.include?(newsub)
  end

  def test_all_active
    active_skills = Skill.all_active
    assert_equal 3, active_skills.size
    assert_true active_skills.include?(@valid_skill)
    assert_true active_skills.include?(skills(:valid_name_max_length))
    assert_true active_skills.include?(skills(:sub_skill))
    assert_false active_skills.include?(skills(:inactive))
  end

end
