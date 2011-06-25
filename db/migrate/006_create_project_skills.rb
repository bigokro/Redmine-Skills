class CreateProjectSkills < ActiveRecord::Migration
  def self.up
    create_table :project_skills do |t|
      t.references :project, :foreign_key => true, :null => false
      t.references :skill, :foreign_key => true, :null => false
      t.references :issue_category, :foreign_key => true, :null => true
      t.column :level, :integer, :default => 1, :null => false
    end
    add_index :project_skills, [:project_id, :skill_id, :issue_category_id], :unique => true, :name => :project_skills_unique
  end

  def self.down
    drop_table :project_skills
  end
end
