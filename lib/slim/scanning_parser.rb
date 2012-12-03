module Slim
  class ScanningParser

    attr_reader :parser, :scanner, :indenter, :liner, :stacks

    def initialize(parser)
      @parser = parser
      @indenter = Indenter.new(self)
      @liner = LineCounter.new(self)
      reset
    end

    def shortcut
      @sc ||= parser.shortcut
    end

    def shortcut_sub(tag)
      shortcut[tag] ? shortcut[tag][0] : tag
    end

    def shortcut_lookup(tag)
      shortcut[tag][1]
    end

    def shortcut_re
      @scre ||= parser.shortcut_re
    end

    def push(object)
      @stacks.push(object)
    end

    def pop(amount = 1)
      return unless amount < stack_depth
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
    end

    def result
      @stacks.shift
    end

    def parse(str)
      @scanner = Scanner.new(str, self)
      i = 0
      until @scanner.eos?
        i = parse_lines(i)
      end
    end

    def scanner
      @scanner
    end

    def parse_lines(i)
      ap "~>" + scanner.rest

      ConsumeWhitespace.try(self, scanner) &&
      HtmlComment.try(self, scanner) ||
      HtmlConditionalComment.try(self, scanner) ||
      SlimComment.try(self, scanner) ||
      TextBlock.try(self, scanner) ||
      InlineHtml.try(self, scanner) ||
      RubyCodeBlock.try(self, scanner) ||
      OutputBlock.try(self, scanner) ||
      EmbeddedTemplate.try(self, scanner) ||
      Doctype.try(self, scanner) ||
      Tag.try(self, scanner, parser.tag_re)

      scanner.terminate if i > 20
      i.succ
    end
  end
end
