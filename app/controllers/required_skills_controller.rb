class RequiredSkillsController < ApplicationController

  before_filter :load_model
  before_filter :authorize

  def add
    name = params[:required_skill][:name]
    skill = Skill.find_by_name(name)
    unless skill
      # Allow users to create new skills on the fly via this form
      skill = Skill.new(:name => name)
      skill.save!
    end
    level = params[:required_skill][:level].to_i
    @required_skill = RequiredSkill.new(:issue => @issue, :skill => skill, :level => level)
    if @required_skill.save
      @required_skill = nil
    end
    refresh_required_skills
  end

  def remove
    @required_skill = RequiredSkill.find(params[:id])
    @required_skill.destroy
    @required_skill = nil
    refresh_required_skills
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  private 
  
  def load_model
    issue_id = params[:issue_id] || params[:required_skill][:issue_id]
    @issue = Issue.find(issue_id)
    @project = @issue.project
  end
  
  def refresh_required_skills
    respond_to do |format|
      format.js do
        render :update do |page|
            page.replace_html "required_skills", :partial => "required_skills"
        end
      end
    end
  end
  
end