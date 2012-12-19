module Slim
module TagQuotedAttributes
  extend self

  def try(parser, scanner, attributes, options)
    return false unless scanner.scan(%r~\s*(\w[:\w-]*)(==?)("|')~)

    atbe = scanner.m1
    esc = options[:escape_quoted_attrs] && scanner.m2 == ?=
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

  def try_eagerly(parser, scanner, attributes, options)
    result = true
    while result
      result = try(parser, scanner, attributes, options)
    end
    result
  end
end
end
