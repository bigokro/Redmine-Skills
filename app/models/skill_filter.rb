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
    case operator
      when "="
        5
      when "!"
        1
      when "!*"
        0
      when ">="
        level        
      when "<="
        6 - level
      else
        0
    end
  end
  
  def where_condition table_alias
    case operator
      when "!"
        "(#{table_alias}.skill_id = #{skill.id} AND #{table_alias}.level != #{level})"
      when "!*"
        # FIXME: This ain't gonna work
        "(#{table_alias}.skill_id != #{skill.id})"
      else
        "(#{table_alias}.skill_id = #{skill.id} AND #{table_alias}.level #{operator} #{level})"
    end
  end
  
  # Returns true if the item should be removed from the list according to this filter
  def excludes? item
    if item.skill == skill
      case operator
        when "="
          item.level != level
        when "!"
          item.level == level
        when "!*"
          true
        when ">="
          item.level < level        
        when "<="
          item.level > level
        else
          false
      end
    else
      false
    end
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
  def excludes? item
    filter_skills = filters.collect{ |f| f.skill }
    return (item.level > 1) && !(filter_skills.include? item.skill)
  end
  
  def where_condition table_alias
    skill_ids = filters.collect{|f| f.skill.nil? ? nil : f.skill.id }.compact
    "0 = (SELECT COUNT(*)
                      FROM required_skills reqs
                     WHERE i.id = reqs.issue_id 
                       AND reqs.level > 1 
                       AND reqs.skill_id NOT IN (#{skill_ids.join(',')}) 
    "
  end
end