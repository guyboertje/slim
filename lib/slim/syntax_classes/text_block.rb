
module Slim
module TextBlock
  extend self

  def try(parser, scanner)
    scanner.indentation
    unless indicator = scanner.scan(%r{(\||') ?})
      return false
    end
    out = [:multi]

    min_indent = scanner.current_indent + indicator.size

    if (part = scanner.shift_text)
      part.strip!
      out.push [:slim, :interpolate, part.concat(?\n)] unless part.empty?
    end
    scanner.line_end
    if block = scanner.scan(%r{((\r?\n)* {#{min_indent},}.*(\r?\n)+)*})
      lines = block.split(/\r?\n/)
      lines.each do |line|
        scanner.liner.inc
        txt = line.slice(min_indent, line.size)
        out.push [:newline]
        out.push([:slim, :interpolate, txt]) if txt
      end
    end
    parser.build [:slim, :text, out]
    parser.build [:static, ' '] if indicator.start_with? ?'
    true
  end
end
end

__END__
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
