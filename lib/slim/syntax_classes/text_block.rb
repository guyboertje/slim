
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
