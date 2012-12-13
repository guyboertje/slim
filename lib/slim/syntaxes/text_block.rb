
module Slim
module TextBlock
  extend self

  def try(parser, scanner, current_indent)
    # unless indicator = scanner.scan(%r{(\||')( ?)(.*)})
    unless indicator = scanner.scan(%r{(\||')( ?)})
      return false
    end
    
    out = [:multi]

    size_of_trailing_space = scanner.m2.size 

    min_indent = current_indent + 1 + size_of_trailing_space

    ap "TextBlock:>#{current_indent}, #{min_indent}, #{scanner.m2.size}"

    # if part = scanner.m3
    if part = scanner.shift_upto_lf
      part.slice(size_of_trailing_space, part.size)
      out.push [:slim, :interpolate, part] unless part.empty?
    end

    if block = scanner.shift_indented_lines(min_indent)
      block.chomp!
      block.lines.each do |line|
        scanner.liner.inc
        next if line =~ /\A\Z/
        txt = line.slice(min_indent, line.size)
        out.push [:newline]
        out.push([:slim, :interpolate, txt])
      end
    end
    parser.last_push [:slim, :text, out]
    parser.last_push [:static, ' '] if indicator.start_with? ?'
    true
  end
end
end
