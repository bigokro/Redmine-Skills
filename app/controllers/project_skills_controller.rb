class ProjectSkillsController < ApplicationController
  unloadable
  
  before_filter :load_model
  before_filter :authorize
  
  def add
    @action = params[:related_skill][:action]
    name = params[:related_skill][:name]
    skill = Skill.find_by_name(name)
    unless skill
      # Allow users to create new skills on the fly via this form
      skill = Skill.new(:name => name)
      skill.save!
    end
    level = params[:related_skill][:level].to_i
    category_id = params[:related_skill][:category_id].to_i
    category = IssueCategory.find_by_id(category_id)
    @related_skill = ProjectSkill.new(:project => @project, :skill => skill, :issue_category => category, :level => level)

    if @related_skill.save
      @related_skill = nil
    end
    refresh_project_skills
  end

  def edit
    @action = params[:related_skill][:action]
    id = params[:related_skill][:id]
    project_skill = ProjectSkill.find(id)
    project_skill.level = params[:related_skill][:level].to_i
    @related_skill = project_skill

    if @related_skill.save
      @related_skill = nil
    end
    refresh_project_skills
  end

  def remove
    @project_skill = ProjectSkill.find(params[:id])
    @project_skill.destroy
    @project_skill = nil
    refresh_project_skills
  rescue ActiveRecord::RecordNotFound
    render_404
  end
  
  private 
  
  def load_model
    project_id = params[:project_id] || params[:related_skill][:related_id]
    @project = Project.find(project_id)
  end
  
  def refresh_project_skills
    respond_to do |format|
      format.js do
        render :update do |page|
            page.replace_html "project_skills", :partial => "skills_project_configs/project_skills"
        end
      end
    end
  end
  
end
