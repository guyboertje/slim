module Slim
  Re = Regexp

  class ScanningParser

    attr_reader :parser, :scanner, :indenter, :stacks

    def initialize(parser, opts)\
      @options = opts
      @parser = parser
      @indenter = Indenter.new(self)
      @eqa = !!@options[:escape_quoted_attrs]
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
      @doctype_done = false
    end

    def result
      res = @stacks.shift
      res.pop if res.last.empty?
      res
    end

    def parse(str)
      @temp_scanner = nil
      @scanner = Scanner.new(str, self)
      @nontag_processor = NontagProcessor.new(self)
      @tag_processor = TagProcessor.new(self, tag_re, shortcut_re, @eqa)
      @nontag_processor.doctype(scanner)
      i = 0
      until @scanner.no_more?
        @nontag_processor.try(scanner) ||
        @tag_processor.try(scanner)

        monitor_raise(i)
        i = i.succ

      end
    end

    def scanner
      @scanner
    end

    def monitor_raise(i)
      return if i < 113
      syntax_error! "line loop limit reached" 
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

