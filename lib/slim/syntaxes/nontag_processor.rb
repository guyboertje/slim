module Slim
  class NontagProcessor

    attr_reader :parser, :line_end_count

    def initialize(parser, tag_processor)
      @parser = parser
      @tag_processor = tag_processor
      @current_indent = 0
      @re_consume = / *\z/
      @re_html_comment = %r~/!( ?)(.*)~
      @re_doctype = %r~doctype(.*)(?=(\n|\z))~i
      @re_html_cond = %r~/\[\s*(.*?) *\].*(?=(\n|\z))~
      @re_embedded = %r~(\w+):\s*(?=(\n|\z))~
      @re_slim_comment = %r~/~
      @re_inline_html = %r~<.+>~
      @re_ruby_code = %r~- ?~
      @re_inline_slim = %r~\+ ?~
      @re_output_block = %r~=(=?)('?)~
      @re_text_block = %r~(\||')( ?)(.*)~
      @re_lf_only = %r~\A\n\z~
      @re_starting_lf = %r~(?<=\n) *~
      @re_starting_ws = %r~\A\s+~
      @re_block_split = %r~\n.*~
      @re_lf = %r~\n~
      @line_end_count = 0
      @lf = ?\n
    end

    def try(scanner)
      consume_whitespace(scanner) &&
      html_comment(scanner) ||
      html_conditional_comment(scanner) ||
      slim_comment(scanner) ||
      text_block(scanner) ||
      inline_html(scanner) ||
      ruby_code_block(scanner) ||
      inline_slim(scanner) ||
      output_block(scanner) ||
      embedded_template(scanner) ||
      tags(scanner)
    end

    def tags(scanner)
      new_lines
      @tag_processor.try(scanner)
    end

    def new_lines
      return unless @line_end_count > 0
      @line_end_count.times do
        parser.last_push [:newline]
      end
      @line_end_count = 0
    end

    def consume_whitespace(scanner)
      if lines = scanner.shift_until_char
        scanner.indentation lines[@re_consume]
        @current_indent = scanner.current_indent
        @line_end_count = lines.count(@lf)
        true
      else
        while scanner.shift_lf do
          parser.last_push [:newline]
        end
        false
      end
    end

    def doctype(scanner)
      consume_whitespace(scanner)
      new_lines
      if scanner.scan(@re_doctype)
        parser.last_push [:html, :doctype, scanner.m1.strip]
      end
    end

    def html_conditional_comment(scanner)
      return false unless scanner.scan(@re_html_cond)
      new_lines

      txt = scanner.m1
      block = [:multi]
      parser.last_push [:html, :condcomment, txt, block]
      parser.push block
      true
    end

    def slim_comment(scanner)
      return false unless comment = scanner.scan(@re_slim_comment)
      new_lines

      scanner.shift_text
      min_indent = @current_indent.succ

      block = scanner.shift_indented_lines(min_indent)
      if block
        block.count(@lf).times do
          parser.last_push [:newline]
        end
      end
      true
    end

    def html_comment(scanner)
      return false unless scanner.scan(@re_html_comment)
      new_lines

      out, first_indent = [:multi], nil

      offset = @current_indent + 2 + scanner.m1.size

      if part = scanner.m2
        part.strip!
        unless part.empty?
          out.push [:slim, :interpolate, part] unless part.empty?
          first_indent = offset
        end
      end

      if block = scanner.shift_indented_lines(offset)
        common_block(out, part, block, first_indent)
      end
      scanner.backup if block && block.end_with?(@lf)
      parser.last_push [:html, :comment, [:slim, :text, out]]
      true
    end

    def text_block(scanner)
      return false unless indicator = scanner.scan(@re_text_block)
      new_lines

      out, first_indent = [:multi], nil

      ind_size, ws_size = scanner.m1.size, scanner.m2.size
      min_indent = @current_indent + ind_size + ws_size

      if part = scanner.m3 and !part.empty?
        _, txt = remove_leading_spaces(part, min_indent)
        out.push [:slim, :interpolate, txt]
        first_indent = min_indent
      end

      if block = scanner.shift_indented_lines(min_indent)
        common_block(out, part, block, first_indent)
      end
      parser.last_push [:slim, :text, out]
      if indicator.start_with? ?'
        parser.last_push [:static, ' ']
      end
      scanner.backup if block && block.end_with?(@lf)
      true
    end

    def common_block(out, part, block, first_indent)
      lines = block.scan(@re_block_split)
      if part.empty?
        lines.first.sub!(@lf, '')
      end
      lines.pop if lines.last == @lf
      lines.each do |line|
        if line.empty?
          out.push [:newline]
        else
          unless first_indent
            line.sub!(@lf, '')
          end
          indent, txt = remove_leading_spaces(line, first_indent)
          first_indent ||= indent
          out.push [:newline], [:slim, :interpolate, txt]
        end
      end
    end

    def remove_leading_spaces(line, amount)
      pieces = if line.start_with?(@lf)
        line.partition(@re_starting_lf)
      else
        line.partition(@re_starting_ws)
      end
      count = pieces[1].size
      if amount.nil?
        pieces[1].clear
      elsif count >= amount
        pieces[1] = " " * (count - amount)
      end
      [count, pieces.join]
    end

    def inline_html(scanner)
      return false unless line = scanner.scan(@re_inline_html)
      new_lines

      block = [:multi]
      parser.last_push [:multi, [:slim, :interpolate, line], block]
      parser.push block
      true
    end

    def ruby_code_block(scanner)
      return false unless scanner.scan(@re_ruby_code)
      new_lines

      lines = scanner.shift_broken_lines

      if scanner.check_next_indent > @current_indent
        block = [:multi]
        parser.last_push [:slim, :control, lines, block]
        parser.push block
      else
        scanner.shift_lf
        parser.last_push [:slim, :control, lines, [:multi, [:newline]]]
      end
      true
    end

    def inline_slim(scanner)
      return false unless scanner.scan(@re_inline_slim)
      new_lines

      line_to_eval = scanner.shift_upto_lf
      template_string = eval(line_to_eval)
      parser.push_scanner Scanner.new(template_string, parser)
      parser.sub_parse
      parser.pop_scanner
      true
    end

    def output_block(scanner)
      return false unless scanner.scan(@re_output_block)
      new_lines

      single = scanner.m1.empty?
      add_ws = !scanner.m2.empty?
      lines = scanner.shift_broken_lines

      if scanner.check_next_indent > @current_indent
        block = [:multi]
        parser.last_push [:slim, :output, single, lines, block]
        parser.last_push [:static, ' '] if add_ws
        parser.push block
      else
        scanner.shift_lf
        parser.last_push [:slim, :output, single, lines, [:multi, [:newline]]]
        parser.last_push [:static, ' '] if add_ws
      end
      true
    end

    def embedded_template(scanner)
      return false unless scanner.scan(@re_embedded)
      new_lines

      out = [:multi]
      min_indent = @current_indent.succ
      engine = scanner.m1

      if block = scanner.shift_indented_lines(min_indent)
        margin, pre = nil, ""
        lines = block.split(@re_lf)
        lines.shift
        lines.each do |line|
          len = line.size
          if margin.nil? && (ind = line[/\A */].size) > 0
            margin = ind
          end
          txt = line.slice(margin || len, len) || ""
          out.push [:newline], [:slim, :interpolate, pre+txt]
          pre = ?\n if margin && pre.empty?
        end
      end
      scanner.backup if block && block.end_with?(@lf)
      parser.last_push [:slim, :embedded, engine, out]
      true
    end
  end
end
