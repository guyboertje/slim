require "strscan"

module Slim

  class Scanner
    # Val = Struct.new(:value)

    def initialize(parser)
      @parser = parser
      @indenter = Indenter.new(self)
      reset
    end

    def push(object)
      @stacks.push(object)
    end

    def pop(amount = 1)
      @stacks.pop(amount)
    end

    def build(part)
      @stacks.last << part
    end

    def stack_depth
      @stacks.size
    end

    def reset
      @indenter.reset
      @stacks = [[:multi]]
      @lineno = 1
    end

    def result
      @stacks.pop
    end

    def parse(str)
      @input = StringScanner.new(str)
      parse_lines until @input.eos?
    end

    def input
      @input
    end

    def parse_lines
      line_end
      indentation
      html_comments
      # html_comments or
      # conditional_html_comments or
      # slim_comment or
      # text_block or
      # inline_html or
      # ruby_code or
      # ruby_output or
      # embedded_template or
      # doctype_decl or
      # html_tag
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

    def check_lf
      @input.check(lf_re)
    end

    def check_indent
      @input.check(ind_re)
    end

    def check_text
      @input.check(txt_re)
    end

    def shift_indent
      @input.scan(ind_re)
    end

    def shift_text
      @input.scan(txt_re)
    end

    def line_end(interim = nil)
      if shift_lf
        @lineno += 1
        if interim.nil?
          build [:newline]
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

    # def peeked_indent
    #   (ind = check_indent) ? ind.size : 0
    # end

    # def parse_text_block(first_line = nil, text_indent = nil, in_tag = false)
    #   result = [:multi]
    #   line_end(false)
    #   if !first_line || first_line.empty?
    #     text_indent = nil
    #   else
    #     result << [:slim, :interpolate, first_line]
    #   end

    #   empty_lines = []

    #   until @input.eos? do
    #     if lf = check_lf # blank line
    #       line_end(false)
    #       empty_lines << ?\n if text_indent
    #     else
    #       if peeked_indent <= current_indent
    #         line = check_text
    #         break unless line.strip.empty?
    #         shift_text
    #         line_end(false)
    #         empty_lines << ?\n if text_indent
    #       end

    #       if !empty_lines.empty?
    #         result << [:slim, :interpolate, empty_lines.join('')]
    #         empty_lines.clear
    #       end
    #       line_end(false)
    #       offset, indent = 0, indentation
    #       if text_indent && (offset = indent - text_indent) < 0
    #         raise "Indentation Error"
    #       end
    #       line = shift_text
    #       result << [:slim, :interpolate, (text_indent ? "\n" : '') + (' ' * offset) + line]
    #       text_indent ||= indent
    #     end
    #   end
    #   result
    # end

    def html_comments
      HtmlComment.try(self)
      # comment = @input.scan(%r{/!( ?)}) or return false
      # self.build [:html, :comment,
      #   [:slim, :text,
      #     parse_text_block(shift_text, current_indent + comment.size)
      #   ]
      # ]
      
      # true
    end

    def html_tag
      return false
    end
    def conditional_html_comments
      return false
    end

    def slim_comment
      return false
    end
    def text_block
      return false
    end
    def inline_html
      return false
    end
    def ruby_code
      return false
    end
    def ruby_output
      return false
    end
    def embedded_template
      return false
    end
    def doctype_decl
      return false
    end
  end
end
