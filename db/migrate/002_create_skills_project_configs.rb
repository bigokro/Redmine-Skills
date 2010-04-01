class CreateSkillsProjectConfigs < ActiveRecord::Migration
  def self.up
    create_table :skills_project_configs do |t|
      t.column :action_on_insufficient_skills, :string, :null => false, :default => 'warn'
      t.references :project, :foreign_key => true, :null => false
    end
    add_index :skills_project_configs, [:project_id], :unique => true, :name => :skills_project_configs_project
  end

  def self.down
    drop_table :skills_project_configs
  end
end
