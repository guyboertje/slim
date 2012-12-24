module Slim
  Re = Regexp

  class ScanningParser

    attr_reader :parser, :scanner, :indenter, :stacks

    def initialize(parser, opts)\
      @options = opts
      @parser = parser
      @indenter = Indenter.new(self)
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

    def escape_quoted_attrs
      @eqa ||= @options[:escape_quoted_attrs]
    end

    def parse_lines(i)
      ConsumeWhitespace.try( self, scanner, indenter.current_indent ) &&
      HtmlComment.try( self, scanner, indenter.current_indent ) ||
      HtmlConditionalComment.try( self, scanner, indenter.current_indent ) ||
      SlimComment.try( self, scanner, indenter.current_indent ) ||
      TextBlock.try( self, scanner, indenter.current_indent ) ||
      InlineHtml.try( self, scanner, indenter.current_indent ) ||
      RubyCodeBlock.try( self, scanner, indenter.current_indent ) ||
      OutputBlock.try( self, scanner, indenter.current_indent ) ||
      EmbeddedTemplate.try( self, scanner, indenter.current_indent ) ||
      Doctype.try( self, scanner, indenter.current_indent ) ||
      parse_tags

      monitor_raise(i)
      i.succ
    end

    def monitor_raise(i)
      return if i < 113
      syntax_error! "line loop limit reached" 
    end

    def parse_tags

      # ap ["parse_tags", scanner.rest]

      done, i = false, 0
      tags, memo, attributes = [], {}, [:html, :attrs]

      begin
        i += 1
        Tag.try( self, scanner, tag_re, shortcut_re, tags, attributes, memo )
        parse_attributes(memo, attributes)
        tags.push attributes
        last_push tags
        done =  TagOutput.try( self, scanner, indenter.current_indent, tags ) ||
                TagClosed.try( self, scanner, tags ) ||
                TagNoContent.try( self, scanner, tags ) ||
                TagText.try( self, scanner, tags, memo )

        monitor_tag_raise(i)

      end until done
      done
    end

    def monitor_tag_raise(i)
      return if i < 13
      syntax_error! "tag loop limit reached" 
    end

    def parse_attributes(memo, attributes)
      TagShortcutAttributes.try( self, scanner, attributes )
      TagDelimitedAttributes.try( self, scanner, memo )

      monitor = Progress.new(scanner)
      while monitor.progress? do
        break if scanner.eol?
        TagSplatAttributes.try( self, scanner, attributes ) ||
        TagQuotedAttributes.try_eagerly( self, scanner, attributes, escape_quoted_attrs ) ||
        TagCodeAttributes.try( self, scanner, attributes, escape_quoted_attrs ) ||
        TagBooleanAttributes.try( self, scanner, attributes, memo )
      end

      if memo[:wrapped_attributes] && scanner.no_more?
        clear_temp_scanner
        memo[:wrapped_attributes] = false
      end
    end

    def syntax_error!(message)
      clear_temp_scanner
      err_pos = scanner.position
      next_lf_pos = scanner.delegate('exist?', /\n/) || 1
      context = scanner.delegate('string')[0, err_pos + next_lf_pos - 1]
      b, lf, line = context.rpartition(/\r?\n/)
      line.strip!
      lineno = b.count(?\n) + 2
      column = err_pos - b.size - lf.size
      column = 1 if column < 1
      column = line.size if column > line.size


      # ap from: "syntax_error", rest: scanner.rest, err_pos: err_pos, next_lf_pos: next_lf_pos, context: context, b:b, lf:lf, line: line, lineno: lineno, column: column

      raise Parser::SyntaxError.new(message, @options[:file], line.strip, lineno, column)
    end
  end
end

