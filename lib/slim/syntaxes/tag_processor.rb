module Slim
  class TagProcessor

    attr_reader :parser

    def initialize(parser, tag_re, shortcut_re, escape_quoted_attrs)
      @parser, @tag_re, @shortcut_re = parser, tag_re, shortcut_re
      @shortcut_part = parser.shortcut.keys.join.prepend('[').concat(']')
      @eqa = escape_quoted_attrs
      @code_finder = CodeFinder.new
      @progress = Progress.new
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

    def monitor_tag_raise
      return if @i < 13
      parser.syntax_error! "tag loop limit reached" 
    end

    def try(scanner)
      @scanner = scanner
      reset
      begin
        @i += 1
        find_tag
        parse_attributes
        @tags.push @attributes
        parser.last_push @tags
        done =  output ||
                closed ||
                no_content ||
                text

        monitor_tag_raise

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
      @progress.reset(scanner)
      while @progress.progress? do
        break if scanner.eol?
        splat_attributes
        quoted_attributes_eagerly
        code_attributes
        boolean_attributes if @wrapped_attributes
      end

      if @wrapped_attributes && scanner.no_more?
        clear_temp_scanner
        @wrapped_attributes = false
      end
    end

    def shortcut_attributes
      @re_sc  ||= %r~(#{@shortcut_part}\w[\w-]*\w)+~
      @re_sc1 ||= %r~(#{@shortcut_part})(\w[\w-]*\w)~
      if scs = scanner.scan(@re_sc)
        scs.scan(@re_sc1).each do |dot, val|
          sub = parser.shortcut_lookup(dot)
          @attributes.push [:html, :attr, sub, [:static, val]]
        end
      end
    end

    def delimited_attributes
      return unless delim_open = scanner.shift_delim

      delim_close = delim_map[delim_open]
      end_re = /#{Re.quote(delim_close)}/m
      part, line, expect = "", " ", 1
      @progress.reset(scanner)
      begin
        @progress.measure
        part = scanner.scan_until(end_re)
        if (part.nil? || part.empty?) && !expect.zero?
          raise "expecting closing ]"
        end
        line.concat(part.squeeze(' '))
        expect += line.count(delim_open)
        expect -= line.count(delim_close)
      end until expect.zero? || @progress.stuck?

      line.chomp!(delim_close) # ignore last closing delimiter
      if line.empty? || @progress.stuck?
        raise "expected to have delimited attributes"
      end
      line.gsub!(lf_re, ' ') # behave like a single line
      line.concat(' ')

      @wrapped_attributes = true
      set_temp_scanner(line)
    end

    def delim_map
      @h1 ||= Hash[?(,?),?[,?],?{,?}]
    end

    def lf_re
      @re4 ||= %r~\r?\n~
    end

    def space_scan_re
      @re_space_scan ||= %r~ |(?=\r?\n)~
    end

    def splat_attributes
      @re_splat ||= %r~\s*\*~
      return false unless splat = scanner.scan(@re_splat)

      @progress.reset(scanner)
      @progress.measure
      part = scanner.scan_until(space_scan_re)
      raise "No part" unless part

      @code_finder.reset(part)
      until @code_finder.done? || @progress.stuck? do

        @progress.measure
        part = scanner.scan_until(space_scan_re) or break
        @code_finder.add(part)
      end

      raise "No code found" unless @code_finder.done?

      code = @code_finder.code
      
      scanner.backup if code.end_with?(' ')

      @attributes.push [:slim, :splat, code.strip]
      true
    end

    def quoted_attributes
      @qre ||= %r~\s*(\w[:\w-]*)(==?)("|')~

      return false unless scanner.scan(@qre)

      atbe = scanner.m1
      esc = @eqa && scanner.m2 == ?=
      qc = scanner.m3
      value = String.new(qc)

      scan_re = %r~#{qc}(?=(=| |\r?\n))~

      @progress.reset(scanner)
      begin
        @progress.measure
        part = scanner.scan_until(scan_re)
        value.concat(part) if part
        expect = value.count(qc) % 2
      end until expect.zero? || @progress.stuck?

      raise "quoted_attributes is stuck" if @progress.stuck?

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
      @re_ca ||= %r~\s*(\w[:\w-]*)(==?)~
      return false unless scanner.scan(@re_ca)

      atbe = scanner.m1
      esc = @eqa && scanner.m2 == ?=

      @progress.reset(scanner)
      @progress.measure
      part = scanner.scan_until(space_scan_re)
      raise "No part" unless part

      @code_finder.reset(part)
      until @code_finder.done? || @progress.stuck? do

        @progress.measure
        part = scanner.scan_until(space_scan_re)
        if part
          @code_finder.add(part)
        else
          break
        end
      end

      raise "No code found" unless @code_finder.done?

      value = @code_finder.code
      
      scanner.backup if value.end_with?(' ')

      value = @code_finder.enclosed_by_delim? ? value[1,value.size - 3] : value.strip

      parser.syntax_error!('Invalid empty attribute') if value.empty?

      @attributes.push [:html, :attr, atbe, [:slim, :attrvalue, esc, value]]

      true
    end

    def boolean_attributes
      @re_bool ||= %r~\s*(\w[:\w-]*)(?=\s|\r?\n)~
      return false unless atbe = scanner.scan(@re_bool)

      @attributes.push [:html, :attr, atbe.strip, [:slim, :attrvalue, false, 'true']]
      true
    end

    def output
      @re_output ||= %r~ *=(=?)('?)\s?~
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
        @tags.push [:slim, :output, single, lines, [:multi, [:newline]]]
        parser.last_push [:static, ' '] if add_ws
      end

      true
    end

    def closed
      @re_closed ||= %r~\s*/(?=(\s|\r?\n))~
      return false unless scanner.scan(@re_closed)

      # add nothing - consume to eol
      scanner.shift_text
      true

    end

    def no_content
      @re_no_content ||= %r~\s*(?=\r?\n)~
      return false unless scanner.scan(@re_no_content)

      content = [:multi]
      @tags.push content
      parser.push content

      true
    end

    def text
      # %r~\s(.*)(?=\r?\n)~
      @re_text ||= %r~\s(.*)~
      pos = scanner.position
      unless scanner.scan(@re_text)
        scanner.scan_until(/(?=\r?\n)/)
        return true
      end

      tag_txt = scanner.m1

      min_indent = @tag_indent + 1 + (pos - @tag_position)

      out = [:multi, [:slim, :interpolate, tag_txt]]

      if block = scanner.shift_indented_lines(min_indent)
        block.lines.each do |line|
          next if line =~ /\A\r?\n\z/
          txt = remove_leading_spaces(line, min_indent)
          txt.prepend(?\n) if txt.chomp!
          out.push [:newline], [:slim, :interpolate, txt]
        end
      end

      # ap from: "tag text", lines: out, dollarslash: $/

      @tags.push [:slim, :text, out]

      true
    end

    def remove_leading_spaces(line, amount)
      pieces = line.partition(/\A\s+/)
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




