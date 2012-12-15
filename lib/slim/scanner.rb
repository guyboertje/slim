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

    def check(re)
      @input.check(re)
    end

    def scan_until(re)
      @input.scan_until(re)
    end

    def position
      @input.pos
    end

    def delegate(action, *args)
      @input.send(action, *args)
    end

    def eos?
      @input.eos?
    end

    def terminate
      @input.terminate
    end

    def rest
      @input.rest
    end

    def match index
      @input[index]
    end

    def m0
      @input[0]
    end

    def m1
      @input[1]
    end

    def m2
      @input[2]
    end

    def m3
      @input[3]
    end

    def qe_lf_re
      @re0 ||= %r{(?=\r?\n)}
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

    def lf_ind_re
      @re4 ||= %r{\r?\n +}
    end

    def lfs_ind_re
      @re5 ||= %r{\r?\n +}
    end

    def lfs_ind_char_re
      @re6 ||= %r{(\r?\n)* +(?=\S)}
    end

    def ws_until_first_char_re
      @re7 ||= %r{\s*(?=\S)}
    end

    def lf_space_plus_re
      @re8 ||= %r{(\r?)\n +}
    end

    def broken_line_re
      @re9 ||= %r{(.*[,\\]\r?\n)*.*(?=\r?\n)}
    end

    def shift_broken_lines
      bls = @input.scan(broken_line_re)
      bls ? bls.gsub(lf_space_plus_re, ?\n) : bls
    end

    def shift_indented_lines(indent)
      @input.scan(%r{((\r?\n)* {#{indent},}.*(\r?\n)+)*})
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

    def shift_until_char
      @input.scan_until(ws_until_first_char_re)
    end

    def shift_upto_lf
      @input.scan_until(qe_lf_re)
    end

    def check_lf
      @input.check(lf_re)
    end

    def eol?
      !!check_lf
    end

    def check_next_indent
      if f = @input.check_until(lfs_ind_char_re)
        f[/ +\z/].size
      else
        current_indent
      end
    end

    def check_indent
      if f = @input.check(ind_re)
        f.size
      else
        current_indent
      end
    end

    def check_text
      @input.check(txt_re)
    end

    def no_more?
      eos? || !@input.exist?(/\S/)
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

    def indentation(ind = shift_indent)
      indent = ind || ""
      @indenter.indent(indent.size)
      current_indent
    end

    def current_indent
      @indenter.current_indent
    end
  end
end
