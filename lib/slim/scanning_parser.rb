module Slim
  Re = Regexp

  class ScanningParser

    attr_reader :parser, :indenter, :stacks, :line_processor

    def initialize(parser, opts)\
      @options = opts
      @parser = parser
      @scanners = []
      @indenter = Indenter.new(self)
      @eqa = !!@options[:escape_quoted_attrs]
      @tag_re = %r~(\*(?=\S+))|(\w[\w:-]*\w|\w+)~
      @sc = parser.shortcut
      @shortcuts_quoted_ored = @sc.keys.map{ |k| Re.quote(k) }.join(?|)
      @sc_re = %r~#{@shortcuts_quoted_ored}~
      @re_lf = %r~\n~
      reset
    end

    def shortcut
      @sc
    end

    def shortcut_sub(tag)
      @sc[tag] ? @sc[tag][0] : tag
    end

    def shortcut_lookup(tag)
      @sc[tag][1]
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
      @doctype_done = false
    end

    def result
      res = @stacks.shift
      res.pop if res.last.empty?
      res
    end

    def scanner
      @scanners.last
    end

    def push_scanner(scanr)
      @scanners.push scanr
    end

    def pop_scanner
      @scanners.pop
    end

    def parse(str)
      push_scanner Scanner.new(str, self)
      @line_processor = NontagProcessor.new(self, TagProcessor.new(self, @tag_re, @sc_re, @eqa))
      line_processor.doctype(scanner)
      sub_parse
    end

    def sub_parse
      i = 0
      until scanner.no_more?
        line_processor.try(scanner)
        monitor_raise(i)
        i = i.succ
      end
    end

    def monitor_raise(i)
      return if i < 113
      syntax_error! "line loop limit reached"
    end

    def syntax_error!(message)
      err_pos = scanner.position
      next_lf_pos = scanner.delegate('exist?', @re_lf) || 1
      context = scanner.delegate('string')[0, err_pos + next_lf_pos - 1]
      b, lf, line = context.rpartition(@re_lf)
      line.strip!
      lineno = b.count(?\n) + 2
      column = err_pos - b.size - lf.size
      column = 1 if column < 1
      column = line.size if column > line.size
      ap from: "syntax_error", stacks: stacks
      # ap from: "syntax_error", rest: scanner.rest, err_pos: err_pos, next_lf_pos: next_lf_pos, context: context, b:b, lf:lf, line: line, lineno: lineno, column: column
      raise Parser::SyntaxError.new(message, @options[:file], line.strip, lineno, column)
    end
  end
end

