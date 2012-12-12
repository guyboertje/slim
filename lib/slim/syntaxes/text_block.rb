
module Slim
module TextBlock
  extend self

  def try(parser, scanner, current_indent)
    unless indicator = scanner.scan(%r{(\||')( ?)(.*)})
      return false
    end
    # ap "TextBlock"
    
    out = [:multi]

    min_indent = current_indent + 1 + scanner.m2.size

    if part = scanner.m3
      part.strip!
      out.push [:slim, :interpolate, part] unless part.empty?
    end

    if block = scanner.shift_indented_lines(min_indent)
      lines = block.split(/\r?\n/)
      scanner.liner.inc
      lines.shift
      lines.each do |line|
        scanner.liner.inc
        txt = line.lstrip
        out.push [:newline]
        out.push([:slim, :interpolate, txt]) unless txt.empty?
      end
    end
    parser.build [:slim, :text, out]
    parser.build [:static, ' '] if indicator.start_with? ?'
    true
  end
end
end
