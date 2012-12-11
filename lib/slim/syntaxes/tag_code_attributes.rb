module Slim
module TagCodeAttributes
  extend self

  def try(parser, scanner, memo, attributes, options)

    return unless scanner.scan(%r~\s*(\w[:\w-]*)(==?)~)

    atbe = scanner.m1
    esc = (scanner.m2 != ?=) && options[:escape_quoted_attrs]
    value = String.new

    expect = 0

    openings, closings = "({[", "]})"
    scan_re = %r~ |(?=\r?\n)~

    begin
      part = scanner.scan_until(scan_re)
      value.concat(part) unless part.nil?
      expect += part.count(openings)
      expect -= part.count(closings)
      # ap from: "TagCodeAttributes", part: part, expect: expect, code: code
    end until expect.zero?

    ap from: "TagCodeAttributes", attr: atbe, esc: esc, quoted: value

    attributes.push [:html, :attr, atbe, [:slim, :attrvalue, esc, value]]

    scanner.eol?
  end
end
end

__END__

    if !(rest.count('{}') % 2).zero?
      raise "unmatched {}s"
    end
    if !(rest.count(%q~"'~) % 2).zero?
      raise "unmatched quotes"
    end

    collector = []
    sections = quoted.scan(%r~\w[:\w-]*==?~)
    sections.reverse!
    sections.each do |section|
      pre, atr, val = quoted.partition(section)
      esc = options[:escape_quoted_attrs] && !atr.end_with?('==')
      atrr = atr.squeeze(?=).chop
      ap from: "TagQuotedAttributes", attr: atrr, val: val, esc: esc, quoted: quoted
      collector.unshift [:html, :attr, atrr, [:escape, false, [:slim, :interpolate, val]]]
      quoted = pre
    end
    attributes.push *collector
