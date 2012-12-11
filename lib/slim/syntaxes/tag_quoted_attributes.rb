module Slim
module TagQuotedAttributes
  extend self

  def try(parser, scanner, memo, attributes, options)

    return unless scanner.scan(%r~\s*(\w[:\w-]*)(==?)("|')~)

    atbe = scanner.m1
    esc = (scanner.m2 != ?=) && options[:escape_quoted_attrs]
    qc = scanner.m3
    value = String.new(qc)

    expect = 1
    scan_re = %r~#{qc} ~

    begin
      part = scanner.scan_until(scan_re)
      value.concat(part) if part
      expect = value.count(qc) % 2
    end until expect.zero?

    value = value[1..-3]

    ap from: "TagQuotedAttributes", attr: atbe, esc: esc, quoted: value, qc: qc

    attributes.push [:html, :attr, atbe, [:escape, esc, [:slim, :interpolate, value]]]

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
