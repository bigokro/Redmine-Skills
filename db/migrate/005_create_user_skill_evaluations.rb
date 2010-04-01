class CreateUserSkillEvaluations < ActiveRecord::Migration
  def self.up
    create_table :user_skill_evaluations do |t|
      t.references :user, :foreign_key => true, :null => false
      t.references :issue, :foreign_key => true, :null => true
      t.column :assessment, :text
      t.references :evaluator, :class_name =>"User", :foreign_key => true, :null => false
      t.column "created_on", :timestamp
    end
    create_table :user_skill_changes do |t|
      t.references :user_skill_evaluation, :foreign_key => true, :null => false
      t.references :skill, :foreign_key => true, :null => false
      t.column :old_level, :integer, :default => 0, :null => false
      t.column :new_level, :integer, :null => false
    end
  end

  def self.down
    drop_table :user_skill_changes
    drop_table :user_skill_evaluations
  end
end
