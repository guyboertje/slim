# "\n   Another comment\n     \n   Another comment\n\n   Another comment\n"
module Slim
module HtmlComment
  extend self

  def try(parser, scanner)
    scanner.indentation
    unless comment = scanner.scan(%r{/!( ?)})
      return false
    end
    out = [:multi]

    min_indent = scanner.current_indent.succ
    offset = min_indent.pred + comment.size

    if (part = scanner.shift_text)
      part.strip!
      out.push [:slim, :interpolate, part] unless part.empty?
    end
    scanner.line_end
    if block = scanner.scan(%r{((\r?\n)* {#{min_indent},}.*(\r?\n)+)*})
      lines = block.split(/\r?\n/)
      lines.each do |line|
        scanner.liner.inc
        txt = (line.slice(offset, line.size) || "").prepend(?\n)
        out.push [:newline]
        out.push([:slim, :interpolate, txt])
      end
    end
    parser.build [:html, :comment, [:slim, :text, out]]
    true
  end
end
end

__END__
  def try(parser)
    parser.scanner.indentation
    unless comment = parser.scanner.scan(%r{/!( ?)})
      return false
    end
    scanner, out = parser.scanner, [:multi]

    min_indent = scanner.current_indent.succ

    if (part = scanner.shift_text)
      part.strip!
      out.push [:slim, :interpolate, part] unless part.empty?
    end
    scanner.line_end
    if block = scanner.scan(%r{((\r?\n)* {#{min_indent},}.*(\r?\n)+)*})
      empty_lines, after_first_line = [], false
      new_scanner = Scanner.new(block, parser)
      until new_scanner.eos? do
        if new_scanner.line_end(false)
          empty_lines.push ?\n
        end
        if line = new_scanner.shift_text
          line.strip!
          if line.empty?
            empty_lines.push(?\n)
          else
            if !empty_lines.empty?
              out.push([:slim, :interpolate, empty_lines.join('')])
              empty_lines.clear
            end
            line.prepend(?\n) if after_first_line
            out.push([:slim, :interpolate, line])
          end
        end
        new_scanner.line_end(false)
        after_first_line = true
      end
    end
    parser.build [:html, :comment, [:slim, :text, out]]
    true
  end
