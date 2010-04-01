class CreateUserSkills < ActiveRecord::Migration
  def self.up
    create_table :user_skills do |t|
      t.references :user, :foreign_key => true, :null => false
      t.references :skill, :foreign_key => true, :null => false
      t.column :level, :integer, :default => 1, :null => false
    end
    add_index :user_skills, [:user_id, :skill_id], :unique => true, :name => :user_skills_unique
  end

  def self.down
    drop_table :user_skills
  end
end
