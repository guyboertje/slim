require "strscan"

module Slim
  class Scanner

    attr_reader :parser, :indenter, :liner, :input

    def initialize(src, parser)
      @parser = parser
      @input = StringScanner.new(src)
      @indenter = parser.indenter
      @liner = parser.liner
    end

    def reset
      @indenter.reset
      @liner.reset
    end

    def scan(re)
      @input.scan(re)
    end

    def eos?
      @input.eos?
    end

    def terminate
      @input.terminate
    end

    def lf_re
      @re1 ||= %r{\r?\n}
    end

    def ind_re
      @re2 ||= %r{ +}
    end

    def txt_re
      @re3 ||= %r{.*}
    end

    def shift_lf
      @input.scan(lf_re)
    end

    def shift_indent
      @input.scan(ind_re)
    end

    def shift_text
      @input.scan(txt_re)
    end

    def check_lf
      @input.check(lf_re)
    end

    def check_indent
      @input.check(ind_re)
    end

    def check_text
      @input.check(txt_re)
    end

    def line_end(interim = nil)
      if shift_lf
        @liner.inc
        if interim.nil?
          @parser.build [:newline]
        elsif interim
          interim << [:newline]
        end
        true
      else
        false
      end
    end

    def indentation
      if indent = shift_indent
        @indenter.indent(indent.size)
      end
      current_indent
    end

    def current_indent
      @indenter.current_indent
    end
  end
end
