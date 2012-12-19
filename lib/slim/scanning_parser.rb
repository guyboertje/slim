module Slim
  Re = Regexp

  class ScanningParser

    attr_reader :parser, :scanner, :indenter, :liner, :stacks

    def initialize(parser, opts)\
      @options = opts
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
      @scre ||= %r~#{shortcuts_quoted_ored}~
    end

    def tag_re
      @tagre ||= %r~(\*(?=\S+))|(\w[\w:-]*\w|\w+)~
    end

    def shortcuts_quoted_ored
      shortcut.keys.map{ |k| Re.quote(k) }.join(?|)
    end

    def push(object)
      @stacks.push(object)
    end

    def pop(amount = 1)
      return unless amount < stack_depth
      @stacks.pop(amount)
    end

    def last_push(part)
      @stacks.last.push part
    end

    def stack_depth
      @stacks.size
    end

    def reset
      @stacks = [[:multi]]
    end

    def result
      res = @stacks.shift
      res.pop if res.last.empty?
      res
    end

    def parse(str)
      @temp_scanner = nil
      @scanner = Scanner.new(str, self)
      i = 0
      until @scanner.no_more?
        i = parse_lines(i)
      end
    end

    def scanner
      @temp_scanner || @scanner
    end

    def set_temp_scanner(alt)
      @temp_scanner = alt
    end

    def clear_temp_scanner
      @temp_scanner = nil
    end

    def line_args(*extras)
      [self, scanner, indenter.current_indent].concat(extras)
    end

    def tag_args(*extras)
      [self, scanner].concat(extras)
    end

    def parse_lines(i)
      ConsumeWhitespace.try( *line_args ) &&
      HtmlComment.try( *line_args ) ||
      HtmlConditionalComment.try( *line_args ) ||
      SlimComment.try( *line_args ) ||
      TextBlock.try( *line_args ) ||
      InlineHtml.try( *line_args ) ||
      RubyCodeBlock.try( *line_args ) ||
      OutputBlock.try( *line_args ) ||
      EmbeddedTemplate.try( *line_args ) ||
      Doctype.try( *line_args ) ||
      parse_tags

      monitor_raise(i)
      i.succ
    end

    def parse_tags
      done, i = false, 0
      tags, memo, attributes = [], {}, [:html, :attrs]

      begin
        i += 1
        done =  Tag.try( *tag_args(tag_re, shortcut_re, tags, attributes, memo) ) ||
                parse_attributes(tags, memo, attributes) ||
                TagOutput.try( *line_args(tags) ) ||
                TagClosed.try( *tag_args(tags) ) ||
                TagNoContent.try( *tag_args(tags) ) ||
                TagText.try( *tag_args(tags, memo) )

        monitor_raise(i)

      end until done
      done
    end

    def monitor_raise(i)
      return if i < 113
      syntax_error! "loop limit reached" 
    end

    def parse_attributes(tags, memo, attributes)
      TagShortcutAttributes.try( *tag_args(attributes) )
      TagDelimitedAttributes.try( *tag_args(memo) )

      monitor = Progress.new(scanner)
      while monitor.progress? do
        TagSplatAttributes.try( *tag_args(attributes) ) ||
        TagQuotedAttributes.try_eagerly( *tag_args(attributes, @options) ) ||
        TagCodeAttributes.try( *tag_args(attributes, @options) ) ||
        TagBooleanAttributes.try( *tag_args(attributes, memo) )
      end

      if memo[:wrapped_attributes] && scanner.no_more?
        clear_temp_scanner
        memo[:wrapped_attributes] = false
      end

      tags.push attributes
      last_push tags

      false
    end

    def syntax_error!(message)
      clear_temp_scanner
      err_pos = scanner.position
      next_lf_pos = scanner.delegate('exist?', /\n/) || 2
      context = scanner.delegate('string')[0, err_pos + next_lf_pos - 1]
      b, lf, line = context.rpartition(/\r?\n/)
      lineno = b.count(?\n) + 2
      column = err_pos - b.size - lf.size - 1

      raise Parser::SyntaxError.new(message, @options[:file], line, lineno, column)
    end
  end
end
