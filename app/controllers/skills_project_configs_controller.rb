class SkillsProjectConfigsController < ApplicationController
  unloadable
  
  menu_item :skills

  before_filter :load_project
  before_filter :authorize

  helper :skills

  def edit
    @skills_project_config = SkillsProjectConfig.find_by_project_id(@project.id)
    unless @skills_project_config
      @skills_project_config = SkillsProjectConfig.new(:project => @project)
      @skills_project_config.save
    end
    @skills = @skills_project_config.project_skills
    if request.post?
      if @skills_project_config.update_attributes(params[:skills_project_config])
        flash[:notice] = l(:notice_successful_update)
      end
    end
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  private
  
  def load_project
    @project = Project.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render_404
  end
  

end
