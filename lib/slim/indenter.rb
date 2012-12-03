module Slim
  class Indenter
    def initialize(parser)
      @parser = parser
      reset
    end

    def reset
      @indents = [0]
    end

    def depth
      @indents.size
    end

    def indent_expected?
      @parser.stack_depth > depth
    end

    def current_indent
      @indents.last
    end

    def indent(amount)
      if amount > current_indent
        @indents << amount
        return nil
      end

      unwind = indent_expected? ? 1 : 0
      idx = @indents.index(amount)
      raise "Malformed indentation at line #{@parser.liner.lineno}, amount: #{amount}, current: #{current_indent}" unless idx
      popped = depth - idx.succ
      
      # ap from: ?+*40, amount: amount, popped: popped, unwind: unwind, stacks: @parser.stacks, indents: @indents

      self.pop(popped)
      @parser.pop(unwind + popped)
    end

    def pop(amount)
      return unless amount < @indents.size
      @indents.pop(amount)
    end
  end
end
