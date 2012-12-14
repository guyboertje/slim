
module Slim
module TextBlock
  extend self

  def try(parser, scanner, current_indent)
    unless indicator = scanner.scan(%r{(\||')( ?)(.*)})
      return false
    end

    out = [:multi]

    ind_count = scanner.m1.size
    ws_count = scanner.m2.size
    min_indent = current_indent + ind_count + ws_count

    first_indent = nil
    # first_indent = min_indent

    # ap from: "TextBlock", min_indent: min_indent, ind_count: ind_count, ws_count: ws_count, current_indent: current_indent
    do_prepend = false

    if part = scanner.m3
      if part && !part.empty?
        _, txt = remove_leading_spaces(part, min_indent)
        out.push [:slim, :interpolate, txt]
        first_indent = min_indent
        do_prepend = true
      end
      # first_indent = nil
    end

    ap from: "TextBlock", min_indent: min_indent, do_prepend: do_prepend, part: part, txt: txt, rest: scanner.rest

    if block = scanner.shift_indented_lines(min_indent)
      block.lines.each do |line|
        scanner.liner.inc
        next if line =~ /\A\Z/
        indent, txt = remove_leading_spaces_block(line, first_indent)
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

# ----------------------------------------------------

  def remove_leading_spaces(line, amount)
    pieces = line.partition(/\A\s+/)
    count = pieces[1].size
    if count >= amount
      pieces[1] = " " * (count - amount)
    end
    [count, pieces.join]
  end

  def remove_leading_spaces_block(line, amount)
    pieces = line.partition(/\A\s+/)
    count = pieces[1].size
    if amount.nil?
      pieces[1].clear
    elsif count >= amount
      pieces[1] = " " * (count - amount)
    end
    ap from: "TextBlock remove_leading_spaces_block", pieces: pieces, amount: amount

    [count, pieces.join]
  end
end
end
