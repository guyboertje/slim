module Slim
  class TagProcessor

    attr_reader :parser

    def initialize(parser, tag_re, shortcut_re, escape_quoted_attrs)
      @parser, @tag_re, @shortcut_re = parser, tag_re, shortcut_re
      @shortcut_part = Re.quote(parser.shortcut.keys.join).prepend('[').concat(']')
      @eqa = escape_quoted_attrs
      @code_finder = CodeFinder.new
      @re_sc  = %r~(#{@shortcut_part}\w[\w-]*)+(?=(\W|\n|\z))~
      @re_sc1 = %r~(#{@shortcut_part})(\w[\w-]*)~

      @re_splat = %r~\s*\*~
      @re_qa = %r~\s*(\w[:\w-]*)(==?)("|')~

      @re_qa_dq = %r~"(?=(=|/|\s|\z))~
      @re_qa_sq = %r~'(?=(=| |/|\n|\z))~

      @hash_re_qa = {?" => @re_qa_dq, ?' => @re_qa_sq}
      @re_ca = %r~\s*(\w[:\w-]*)(==?)~
      @re_bool = %r~\s*(\w[:\w-]*)(?=\s|\n|\z)~
      @re_output = %r~[[:blank:]]*=(=?)('?)\s?~

      @re_closed = %r~[[:blank:]]*/~

      @re_no_content = %r~[[:blank:]]*(?=(\n|\z))~
      @re_text = %r~\s(.*)~
      @re_lf = %r~\n~
      @re_space_scan = %r~ |(?=(\n|\z))~
      @delim_map = Hash[?(,?),?[,?],?{,?}]
      @delim_close_map = {}
      @delim_map.each do |k,v|
        @delim_close_map[k] = /#{Re.quote(v)}/m
      end
      @re_lf_only = %r~\A\n\z~
      @re_starting_ws = %r~\A\s+~
      @re_until_lf = %r~(?=(\n|\z))~
      @re_colon = %r~:[[:blank:]]*~
      @lf = ?\n
      @eq = ?=
      @sp = " "
    end

    def reset
      @done, @i = false, 0
      @tags, @attributes = [], [:html, :attrs]
      @tag_indent, @tag_position = nil, nil
      @wrapped_attributes = false
    end

    def scanner
      @temp_scanner || @scanner
    end

    def set_temp_scanner(line)
      alt = Scanner.new(line, parser)
      @temp_scanner = alt
    end

    def clear_temp_scanner
      @temp_scanner = nil
      @scanner
    end

    # def monitor_tag_raise
    #   return if @i < 13
    #   parser.syntax_error! "tag loop limit reached" 
    # end

    def try(scanner)
      @scanner = scanner
      reset
      begin
        # @i += 1
        find_tag
        parse_attributes
        @tags.push @attributes
        parser.last_push @tags
        done =  inline_tag ||
                output ||
                closed ||
                no_content ||
                end_of_template ||
                text
        # monitor_tag_raise

      end until done
      done
    end

    def find_tag
      @tag_indent = scanner.current_indent
      @tag_position = scanner.position

      tag = if sc = scanner.check(@shortcut_re)
              parser.shortcut_sub(sc)
            else
              scanner.scan(@tag_re)
            end

      unless tag
        # raise "should be a tag, all other options tried"
        return true
      end

      scanner.backup if tag == ?*

      @tags.concat [:html, :tag, tag]
    end

    def parse_attributes
      shortcut_attributes
      unless @wrapped_attributes
        delimited_attributes
      end
      scanner.rec_position(:parse_attributes)
      begin
        break if scanner.eol?
        splat_attributes
        quoted_attributes_eagerly
        code_attributes
        boolean_attributes if @wrapped_attributes
      end until scanner.stuck?(:parse_attributes)

      if @wrapped_attributes && scanner.no_more?
        clear_temp_scanner
        @wrapped_attributes = false
      end
    end

    def shortcut_attributes
      if scs = scanner.scan(@re_sc)
        scs.scan(@re_sc1).each do |dot, val|
          sub = parser.shortcut_lookup(dot)
          @attributes.push [:html, :attr, sub, [:static, val]]
        end
      end
    end

    def delimited_attributes
      return unless delim_open = scanner.shift_delim

      delim_close = @delim_map[delim_open]
      part, line, expect = "", " ", 1
      scanner.rec_position(:delimited_attributes)
      stuck_scanner = false
      begin
        part = scanner.scan_until(@delim_close_map[delim_open])
        if (part.nil? || part.empty?) && !expect.zero?
          raise "expecting closing ]"
        end
        line.concat(part.squeeze(@sp))
        expect += line.count(delim_open)
        expect -= line.count(delim_close)
        stuck_scanner = scanner.stuck?(:delimited_attributes)
      end until expect.zero? || stuck_scanner

      line.chomp!(delim_close) # ignore last closing delimiter
      if line.empty? || stuck_scanner
        raise "expected to have delimited attributes"
      end
      line.count(@lf).times { parser.last_push [:newline] }
      line.gsub!(@re_lf, ' ') # behave like a single line
      line.concat(' ')
      @wrapped_attributes = true
      set_temp_scanner(line)
    end

    def splat_attributes
      return false unless splat = scanner.scan(@re_splat)

      part = scanner.scan_until(@re_space_scan)
      raise "No part" unless part

      scanner.rec_position(:splat_attributes)
      @code_finder.reset(part)
      until @code_finder.done? do
        part = scanner.scan_until(@re_space_scan) or break
        @code_finder.add(part)
        break if scanner.stuck?(:splat_attributes)
      end

      raise "No code found" unless @code_finder.done?

      code = @code_finder.code
      
      scanner.backup if code.end_with?(@sp)

      @attributes.push [:slim, :splat, code.strip]
      true
    end

    def quoted_attributes
      return false unless scanner.scan(@re_qa)

      atbe = scanner.m1
      esc = @eqa && scanner.m2 == @eq
      qc = scanner.m3
      value = String.new(qc)
      scanner.rec_position(:quoted_attributes)
      scan_re = @hash_re_qa[qc]
      begin
        part = scanner.scan_until(scan_re)
        value.concat(part) if part
        expect = value.count(qc) % 2
        raise "quoted_attributes is stuck" if scanner.stuck?(:quoted_attributes)
      end until expect.zero?

      value = value[1..-2]

      @attributes.push [:html, :attr, atbe, [:escape, esc, [:slim, :interpolate, value]]]
      true
    end

    def quoted_attributes_eagerly
      result = true
      while result
        result = quoted_attributes
      end
      result
    end

    def code_attributes
      return false unless scanner.scan(@re_ca)

      atbe = scanner.m1
      esc = scanner.m2 == @eq

      part = scanner.scan_until(@re_space_scan)
      raise "No part" unless part

      scanner.rec_position(:code_attributes)
      @code_finder.reset(part)
      until part.nil? || @code_finder.done? do
        part = scanner.scan_until(@re_space_scan)
        @code_finder.add(part) if part
        break if scanner.stuck?(:code_attributes)
      end

      value = @code_finder.code || ""
      scanner.backup if value.end_with?(@sp)
      value = @code_finder.enclosed_by_delim? ? value[1, value.size - 3] : value.strip

      parser.syntax_error!('Invalid empty attribute') if value.empty?

      @attributes.push [:html, :attr, atbe, [:slim, :attrvalue, esc, value]]
      true
    end

    def boolean_attributes
      return false unless atbe = scanner.scan(@re_bool)
      @attributes.push [:html, :attr, atbe.strip, [:slim, :attrvalue, false, 'true']]
      true
    end

    def inline_tag
      return false unless scanner.scan(@re_colon)
      
      parser.syntax_error!('Expected tag') unless scanner.check(@tag_re) || scanner.check(@re_sc)

      content = [:multi]
      @tags.push content
      i = parser.stacks.size
      parser.push content
      flag = try(scanner)
      parser.stacks.delete_at(i)
      flag
    end

    def output
      return false unless scanner.scan(@re_output)

      single = scanner.m1.empty?
      add_ws = !scanner.m2.empty?

      lines = scanner.shift_broken_lines
      next_indent = scanner.check_next_indent

      if next_indent > @tag_indent
        block = [:multi]
        @tags.push [:slim, :output, single, lines, block]
        parser.last_push [:static, ' '] if add_ws
        parser.push block
      else
        scanner.shift_lf
        @tags.push [:slim, :output, single, lines, [:multi, [:newline]]]
        parser.last_push [:static, ' '] if add_ws
      end

      true
    end

    def closed
      return false unless scanner.scan(@re_closed)
      scanner.shift_text # add nothing - consume to eol
      true
    end

    def no_content
      return false unless scanner.scan(@re_no_content)
      content = [:multi]
      @tags.push content
      parser.push content
      true
    end

    def end_of_template
      return false unless scanner.eos?
      content = [:multi, [:newline]]
      @tags.push content
      parser.push content
      true
    end

    def text
      pos = scanner.position
      unless scanner.scan(@re_text)
        scanner.scan_until(@re_until_lf)
        return true
      end

      tag_txt = scanner.m1

      min_indent = @tag_indent.succ + (pos - @tag_position)

      out = [:multi, [:slim, :interpolate, tag_txt]]

      if block = scanner.shift_indented_lines(min_indent)
        block.lines.each do |line|
          next if line =~ @re_lf_only
          txt = remove_leading_spaces(line, min_indent)
          txt.prepend(?\n) if txt.chomp!
          out.push [:newline], [:slim, :interpolate, txt]
        end
      end
      scanner.backup if block && block.end_with?(@lf)
      @tags.push [:slim, :text, out]
      true
    end

    def remove_leading_spaces(line, amount)
      pieces = line.partition(@re_starting_ws)
      count = pieces[1].size
      if count > amount
        pieces[1] = " " * (count - amount)
      else
        pieces[1].clear
      end
      pieces.join
    end

  end
end
