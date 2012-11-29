module Slim
  class Indenter
    def initialize(scanner)
      @scanner = scanner
      reset
    end

    def reset
      @indents = [0]
    end

    def depth
      @indents.size
    end

    def indent_expected?
      @scanner.stack_depth > depth
    end

    def current_indent
      @indents.last
    end

    def indent(amount)
      if amount > current_indent
        @indents << amount
        return nil
      end
      
      ap stacks: @scanner.stacks

      unwind = indent_expected? ? 1 : 0
      idx = @indents.index(amount)
      raise 'Malformed indentation' unless idx
      popped = depth - idx
      @indents.pop(popped)
      @scanner.pop(unwind + popped)
    end
  end
end
