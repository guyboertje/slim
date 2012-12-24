module Slim
module TagQuotedAttributes
  extend self

  def quoted_re
    @qre ||= %r~\s*(\w[:\w-]*)(==?)("|')~
  end

  def try(parser, scanner, attributes, escape_quoted_attrs)
    return false unless scanner.scan(quoted_re)

    atbe = scanner.m1
    esc = escape_quoted_attrs && scanner.m2 == ?=
    qc = scanner.m3
    value = String.new(qc)

    scan_re = %r~#{qc}(?=(=| |\r?\n))~

    monitor = Progress.new(scanner)
    begin
      monitor.measure
      part = scanner.scan_until(scan_re)
      value.concat(part) if part
      expect = value.count(qc) % 2
    end until expect.zero? || monitor.stuck?

    raise "TagQuotedAttributes is stuck" if monitor.stuck?

    value = value[1..-2]

    # ap from: "TagQuotedAttributes", value: value if value.end_with? ?\r

    attributes.push [:html, :attr, atbe, [:escape, esc, [:slim, :interpolate, value]]]

    true
  end

  def try_eagerly(parser, scanner, attributes, escape_quoted_attrs)
    result = true
    while result
      result = try(parser, scanner, attributes, escape_quoted_attrs)
    end
    result
  end
end
end
