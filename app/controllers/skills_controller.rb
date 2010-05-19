class SkillsController < ApplicationController
  unloadable
  
  before_filter :load_skill, :except => [:index, :new]
  before_filter :authorize_global

  helper :skills
  include SkillsHelper

  def index
    @skills = Skill.find(:all, :conditions => "super_skill_id IS NULL", :order => "name")
    @users = User.find(:all, :order => "login").select{|u| !u.anonymous?}
  end
  
  def show
  end
  
  def new
    @skill = Skill.new(params[:skill])
    if request.post?
      if @skill.save
        flash[:notice] = l(:notice_successful_create)
        redirect_to( :action => 'show', :project_id => @project, :id => @skill )
      end
    end
  end
  
  def edit
    if request.post?
      if @skill.update_attributes(params[:skill])
        flash[:notice] = l(:notice_successful_update)
        redirect_to :action => 'show', :project_id => @project, :id => @skill
      end
    end
  end
  
  def destroy
    if @skill.destroy
      flash[:notice] = l(:notice_successful_delete)
    end
    redirect_to :action => 'index', :project_id => @project
  end
  
  private
  
  def load_skill
    @skill = Skill.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render_404
  end
  
  def authorize_global
    authorize params[:controller], params[:action], :global => true
  end
end