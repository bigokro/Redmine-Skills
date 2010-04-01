class CreateSkills < ActiveRecord::Migration
  def self.up
    create_table :skills do |t|
      t.column :name, :string, :null => false
      t.column :description, :string
      t.column :details, :text
      t.column :active, :bool, :null => false, :default => true
      t.references :super_skill, :class_name =>"Skill", :foreign_key => true, :null => true
    end
    add_index :skills, [:name], :unique => true, :name => :skills_name
  end

  def self.down
    drop_table :skills
  end
end
