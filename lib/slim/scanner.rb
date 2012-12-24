require "strscan"

module Slim
  class Scanner

    attr_reader :parser, :indenter, :input

    def initialize(src, parser)
      @parser = parser
      @input = StringScanner.new(src)
      @indenter = parser.indenter
    end

    def reset
      @indenter.reset
      @liner.reset
    end

    def scan(re)
      @input.scan(re)
    end

    def scan_until(re)
      @input.scan_until(re)
    end

    def check(re)
      @input.check(re)
    end

    def check_until(re)
      @input.check_until(re)
    end

    def position
      @input.pos
    end

    def backup(n = 1)
      pos = position
      @input.pos = pos - n
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

    def any_char_re
      @re10 ||= %r~\S~
    end

    def delim_map
      @h1 ||= Hash[?(,?),?[,?],?{,?}]
    end

    def delim_re
      @re11 ||= Re.new( delim_map.keys.map{|k| Re.quote(k)}.join(?|) )
    end

    def just_spaces_re
      @re13 ||= %r~ +\z~
    end

    def shift_delim
      scan(delim_re)
    end

    def shift_broken_lines
      bls = scan(broken_line_re)
      if bls
        bls.gsub(lf_space_plus_re, ?\n)
      else
        shift_text
      end
    end

    def shift_indented_lines(indent)
      scan(%r~((\r?\n)* {#{indent},}.*(\r?\n)+)*~)
    end

    def shift_lf
      scan(lf_re)
    end

    def shift_indent
      scan(ind_re)
    end

    def shift_text
      scan(txt_re)
    end

    def shift_until_char
      scan_until(ws_until_first_char_re)
    end

    def shift_upto_lf
      scan_until(qe_lf_re)
    end

    def check_lf
      check(lf_re)
    end

    def eol?
      !!check_lf
    end

    def check_next_indent
      if f = check_until(lfs_ind_char_re)
        f[just_spaces_re].size
      else
        current_indent
      end
    end

    def check_indent
      if f = check(ind_re)
        f.size
      else
        current_indent
      end
    end

    def check_text
      check(txt_re)
    end

    def no_more?
      eos? || !@input.exist?(any_char_re)
    end

    def line_end(interim = nil)
      if shift_lf
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
