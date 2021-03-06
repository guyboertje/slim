require "strscan"

module Slim
  class Scanner

    attr_reader :parser, :indenter, :input

    def initialize(src, parser)
      @parser = parser
      @input = StringScanner.new(src)
      @indenter = parser.indenter
      @qe_lf_re = %r~(?=\n)~
      @lf_re = %r~\n~
      @ind_re = %r~ +~
      @txt_re= %r~.*~
      @lfs_ind_char_re = %r~(\n)* +(?=\S)~
      @ws_until_first_char_re = %r~\s*(?=\S)~
      @lf_space_plus_re = %r~()\n +~
      @broken_line_re = %r~(.*[,\\]\n)*.*(?=(\n|\z))~
      @any_char_re = %r~\S~
      @delim_map = Hash[?(,?),?[,?],?{,?}]
      @delim_re = Re.new( @delim_map.keys.map{|k| Re.quote(k)}.join(?|) )
      @spaces_before_char = %r~ *(?=\S|\Z)~
      @indent_re_cache = {}
      @progress = {}
    end

    def reset
      @indenter.reset
    end

    def rec_position(key = :overall)
      @progress[key] = @input.pos
    end

    def stuck?(key = :overall)
      before = @progress[key]
      before == @progress.store(key, @input.pos)
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

    def shift_delim
      scan(@delim_re)
    end

    def shift_broken_lines
      bls = scan(@broken_line_re)
      if bls
        bls.gsub(@lf_space_plus_re, ?\n)
      else
        shift_text
      end
    end

    def shift_indented_lines(indent)
      re = @indent_re_cache[indent] ||= %r~((\n)* {#{indent},}.*(\n)?)*~
      scan(re)
    end

    def shift_lf
      scan(@lf_re)
    end

    def shift_indent
      scan(@ind_re)
    end

    def shift_text
      scan(@txt_re)
    end

    def shift_until_char
      scan_until(@ws_until_first_char_re)
    end

    def shift_upto_lf
      scan_until(@qe_lf_re)
    end

    def check_lf
      check(@lf_re)
    end

    def eol?
      !!check_lf
    end

    def check_next_indent
      if f = check_until(@lfs_ind_char_re)
        f[@spaces_before_char].size
      else
        current_indent
      end
    end

    def check_indent
      if f = check(@ind_re)
        f.size
      else
        current_indent
      end
    end

    def check_text
      check(@txt_re)
    end

    def no_more?
      eos? || !@input.exist?(@any_char_re)
    end

    def indentation(ind = shift_indent)
      indent = ind || ""
      # ap from: "indentation", indent: indent, rest: self.rest
      @indenter.indent(indent.size)
      current_indent
    end

    def current_indent
      @indenter.current_indent
    end
  end
end
