module Asm
  def self.asm(&block)
    parser = Parser.new
    parser.instance_eval &block
    parser.operations
    evaluator = Evaluator.new parser.labels
    evaluator.evaluate parser.operations
    evaluator.registers.map(&:value)
  end

  class Parser
    attr_accessor :ax, :bx, :cx, :dx
    attr_reader :operations, :labels

    def initialize
      @ax = :ax
      @bx = :bx
      @cx = :cx
      @dx = :dx
      @operations = []
      @labels = []
      @instruction_names = [:mov, :cmp, :inc, :dec, :jmp, :je, :jne, :jl, :jle, :jg, :jge]
    end

    def label(label)
      label.position = @operations.size
      @labels << label
    end

    def method_missing(name, *args)
      if @instruction_names.include? name
        @operations << [name, args]
      else
        if @labels.select { |label| label.name == name }.empty?
          Label.new name
        else
          @labels.select { |label| label.name == name }.first
        end
      end
    end
  end

  class Register
    attr_accessor :value, :name

    def initialize(name)
      @value = 0
      @name = name
    end
  end

  class Label
    attr_accessor :position, :name

    def initialize(name="", position=-1)
      @position = position
      @name = name
    end
  end

  class Evaluator
    attr_reader :next
    attr_accessor :ax, :bx, :cx, :dx

    def initialize(labels)
      @next = 0
      @ax = Register.new :ax
      @bx = Register.new :bx
      @cx = Register.new :cx
      @dx = Register.new :dx
      @labels = labels
      @last_cmp = 0
    end

    def evaluate(operations)
      while @next < operations.size
        operation, arg1, arg2 = operations[@next].flatten
        arg1 = self.public_send arg1 if arg1.is_a? Symbol
        arg2 = (self.public_send arg2).value if arg2.is_a? Symbol
        if arg2
          self.public_send operation, arg1, arg2
        else
          self.public_send operation, arg1
        end
      end
    end

    def registers
      [@ax, @bx, @cx, @dx]
    end

    def mov(register, source)
      register.value = source
      @next += 1
    end

    def inc(register, value=1)
      register.value += value
      @next += 1
    end

    def dec(register, value=1)
      register.value -= value
      @next += 1
    end

    def cmp(register, source)
      @last_cmp = register.value <=> source
      @next += 1
    end

    def jmp(where)
      if where.is_a? Label
        where = @labels.select { |label| label.name == where.name }.first.position
      end
      @next = where
    end

    jumps = {
      :je => :==,
      :jne => :!=,
      :jl => :<,
      :jle => :<=,
      :jg => :>,
      :jge => :>=,
    }

    jumps.each do |jump, operation|
      define_method jump.to_s do |where|
        if @last_cmp.public_send operation, 0
          return jmp where
        end
        @next += 1
      end
    end
  end
end