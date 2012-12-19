module Slim
  class LineCounter

    attr_reader :lineno

    def initialize(scanner)
      @scanner = scanner
      reset
    end

    def reset
      @lineno = 1
    end

    def inc
      @lineno = @lineno.succ
    end
    
    def advance(count)
      return if count.zero?
      @lineno += count
    end

    def count(string)
      return unless string
      advance string.count(?\n)
      string
    end

    def uncount(string)
      @lineno -= string.count(?\n)
      string
    end
  end
end
