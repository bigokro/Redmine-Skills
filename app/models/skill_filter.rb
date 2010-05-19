# A SkillFilter is a non-persistent object which contains the data and logic
# related to filtering either users or issues based on skills and levels
# A single SkillFilter can refer to one Skill, a level, and an operator on that level
class SkillFilter
  attr_accessor :skill, :level, :operator

  OPERATORS = { 
                  ">="  => :label_greater_or_equal,
                  "<="  => :label_less_or_equal,
                  "="   => :label_equals, 
                  "!"   => :label_not_equals,
                  "!*"  => :label_none
                }

  LEVELS = (1..5).to_a
  
  def self.operators
    [">=", "<=", "=", "!", "!*"]
  end
  
  def self.options_for_operators
    self.operators.collect{|key| [I18n.t(OPERATORS[key]), key]}
  end
  
  def self.options_for_levels
    LEVELS
  end

  def initialize(values = {})
    @skill = values[:skill]
    @level = values[:level]
    @operator = values[:operator]
  end
  
  # Rarity is a measure of how difficult it is to match this filter
  # That is, an estimate of how few or how many users or issues would be returned
  # as a result of this filter.
  # In practice, only one or two filters in a query may be used against the database;
  # the rest will be used to filter the results in-memory.
  # In order to improve performance, the filters that return the fewest results
  # should be the ones used in the initial database query.
  # A more sophisticated solution would be to use database histograms... maybe some day...
  def rarity
    case @operator
      when "="
        5
      when "!"
        1
      when "!*"
        0
      when ">="
        @level        
      when "<="
        6 - @level
      else
        0
    end
  end
  
  def where_condition table_alias
    case @operator
      when "!"
        "(#{table_alias}.skill_id = #{@skill.id} AND #{table_alias}.level != #{@level})"
      when "!*"
        # FIXME: This ain't gonna work
        "(#{table_alias}.skill_id != #{@skill.id})"
      else
        "(#{table_alias}.skill_id = #{@skill.id} AND #{table_alias}.level #{@operator} #{@level})"
    end
  end
  
  # Returns true if the item should be removed from the list according to this filter
  # The first parameter is an array of objects with skills and levels (RequiredSkills or UserSkills)
  # The second is a boolean that indicates what to return if the skill level list
  # has no items with a skill that matches the filter
  # (Generally, this is true for testing users - they should be excluded if they don't have the skill -
  # and false for issues - it's ok if a user possesses a skill that isn't required by an issue)
  def excludes? skill_level_list, no_match_result = true
    matching_skills = skill_level_list.select{|sl| sl.skill == @skill}
    return (no_match_result && @operator != "!*") if matching_skills.empty?
    excluded_skills = matching_skills.select do |mskill|
      case @operator
        when "="
          mskill.level != @level
        when "!"
          mskill.level == @level
        when "!*"
          true
        when ">="
          mskill.level < @level        
        when "<="
          mskill.level > @level
        else
          false
      end
    end
    return !excluded_skills.empty?
  end
end

# This class is a filter that indicates that the item being tested (generally an issue)
# should have no other skill levels (i.e. required skills) beyond what is contained
# in an array of skill filters (of which it is part)
# For this, it must have a reference to the array it's in  
class NoOtherSkillsFilter < SkillFilter
  attr_accessor :filters
 
  # If this is present, it trumps all others
  def rarity
    6
  end

  # Checks that the item has no skill levels that aren't referenced by one of the skill filters
  # The common use case for this is a set of filters from a user looking for issues
  # If the issue has any required skills that the user doesn't possess, it should be 
  # excluded by this filter
  # TODO: Configuration for the case of implicit skills (i.e. a required skill of level 1)
  def excludes? skill_level_list, no_match_result = true
    filter_skills = @filters.collect{ |f| f.skill }
    unmatched_skills = skill_level_list.select do |sl|
      (sl.level > 1) && !(filter_skills.include? sl.skill)
    end
    return !unmatched_skills.empty? 
  end
  
  def where_condition table_alias
    skill_ids = @filters.collect{|f| f.skill.nil? ? nil : f.skill.id }.compact
    "0 = (SELECT COUNT(*)
                      FROM required_skills reqs
                     WHERE i.id = reqs.issue_id 
                       AND reqs.level > 1 
                       AND reqs.skill_id NOT IN (#{skill_ids.join(',')}) 
    )"
  end
end