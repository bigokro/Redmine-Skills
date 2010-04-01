# Matches users to issues based on skill levels and required skills
class SkillsMatcherController < ApplicationController
  helper :skills
  include SkillsHelper
  include SkillsMatcherHelper

  def find_requirements_for_user
    @user = Skill.find(:all, :conditions => "super_skill_id IS NULL", :order => "name")
    @users = User.find(:all, :order => "login")
  end
  
  def find_users_for_requirement
    @user = Skill.find(:all, :conditions => "super_skill_id IS NULL", :order => "name")
    @users = User.find(:all, :order => "login")
  end
  
end