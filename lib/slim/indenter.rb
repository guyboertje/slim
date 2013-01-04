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

      # ap from: "Indenter indent", amount: amount

      if amount > current_indent
        @indents << amount
        return nil
      end

      unwind = indent_expected? ? 1 : 0
      idx = @indents.index(amount)
      # unless idx

      @parser.syntax_error!("Malformed indentation, amount: #{amount}, current: #{current_indent}") unless idx
      popped = depth - idx.succ
      
      # ap from: "Indenter indent", popped: popped, unwind: unwind, indents: @indents, stacks: @parser.stacks

      self.pop(popped)
      @parser.pop(unwind + popped)
    end

    def pop(amount)
      return unless amount < @indents.size
      @indents.pop(amount)
    end
  end
end
