class CreateRequiredSkills < ActiveRecord::Migration
  def self.up
    create_table :required_skills do |t|
      t.references :issue, :foreign_key => true, :null => false
      t.references :skill, :foreign_key => true, :null => false
      t.column :level, :integer, :default => 1, :null => false
    end
    add_index :required_skills, [:issue_id, :skill_id], :unique => true, :name => :required_skills_unique
  end

  def self.down
    drop_table :required_skills
  end
end
