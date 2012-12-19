
module Slim
module TextBlock
  extend self

  def try(parser, scanner, current_indent)
    unless indicator = scanner.scan(%r{(\||')( ?)(.*)})
      return false
    end

    out = [:multi]

    ind_size, ws_size = scanner.m1.size, scanner.m2.size
    min_indent = current_indent + ind_size + ws_size

    first_indent, do_prepend = nil, false

    if part = scanner.m3 and !part.empty?
      _, txt = remove_leading_spaces(part, min_indent)
      out.push [:slim, :interpolate, txt]
      first_indent = min_indent
      do_prepend = true
    end

    if block = scanner.shift_indented_lines(min_indent)
      block.lines.each do |line|
        next if line =~ /\A\r?\n\z/
        indent, txt = remove_leading_spaces(line, first_indent)
        first_indent ||= indent
        txt.prepend(?\n) if txt.chomp! && do_prepend
        out.push [:newline]
        out.push([:slim, :interpolate, txt])
        do_prepend = true
      end
    end
    parser.last_push [:slim, :text, out]
    parser.last_push [:static, ' '] if indicator.start_with? ?'
    true
  end

  def remove_leading_spaces(line, amount)
    pieces = line.partition(/\A\s+/)
    count = pieces[1].size
    if amount.nil?
      pieces[1].clear
    elsif count >= amount
      pieces[1] = " " * (count - amount)
    end
    [count, pieces.join]
  end
end
end
