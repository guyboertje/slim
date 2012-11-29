module Slim
  class ScanningParser

    attr_reader :indenter, :liner, :stacks

    def initialize(parser)
      @parser = parser
      @indenter = Indenter.new(self)
      @liner = LineCounter.new(self)
      reset
    end

    def push(object)
      @stacks.push(object)
    end

    def target(object)
      @targets.push(object)
    end

    def untarget(amount = 1)
      @targets.pop(amount)
    end

    def pop(amount = 1)
      @stacks.pop(amount)
    end

    def build(part)
      @stacks.last << part
    end

    def stack_depth
      @stacks.size
    end

    def reset
      @stacks = [[:multi]]
      @targets = []
    end

    def result
      @stacks.shift
    end

    def parse(str)
      @scanner = Scanner.new(str, self)
      parse_lines until @scanner.eos?
    end

    def scanner
      @scanner
    end

    def parse_lines
      scanner.line_end
      HtmlComment.try(self, scanner) or
      HtmlConditionalComment.try(self, scanner)
      HtmlComment.try(self, scanner) or
      TextBlock.try(self, scanner) or
      InlineHtml.try(self, scanner)
      # inline_html or
      # ruby_code or
      # ruby_output or
      # embedded_template or
      # doctype_decl or
      # html_tag
      @scanner.terminate
    end
  end
end
