class TodoList
  include Enumerable

  attr_accessor :tasks

  def each(&block)
    @tasks.each(&block)
  end

  def self.parse(text)
    lines = text.lines.map { |line| line.split('|') }
    tasks = lines.map do |status, description, priority, tags|
      Task.new status, description, priority, tags
    end

    new tasks
  end

  def initialize(tasks)
    @tasks = tasks
  end

  def filter(criteria)
    TodoList.new @tasks.select { |task| criteria.match? task }
  end

  def adjoin(other_todo_list)
    TodoList.new (@tasks + other_todo_list.tasks).uniq
  end

  def tasks_todo
    filter(Criteria.status :todo).tasks.count
  end

  def tasks_completed
    filter(Criteria.status :done).tasks.count
  end

  def tasks_in_progress
    filter(Criteria.status :current).tasks.count
  end

  def completed?
    count_by_status(:done) == tasks.count
  end
end

class Task
  attr_reader :status, :description, :priority, :tags

  def initialize(status, description, priority, tags)
    @status = status.strip.downcase.to_sym
    @description = description.strip
    @priority = priority.strip.downcase.to_sym
    @tags = tags.split(',').map(&:strip)
  end

end

module Criteria
  def self.status(status)
    Criterion.new { |task| task.status == status }
  end

  def self.priority(priority)
    Criterion.new { |task| task.priority == priority }
  end

  def self.tags(tags_list)
    Criterion.new { |task| task.tags | tags_list == task.tags }
  end
end

class Criterion
  def initialize(&block)
    @matching = block
  end

  def match?(task)
    @matching.call task
  end

  def &(other)
    Criterion.new { |task| self.match?(task) and other.match?(task) }
  end

  def |(other)
    Criterion.new { |task| self.match?(task) or other.match?(task) }
  end

  def !
    Criterion.new { |task| not match?(task) }
  end
end