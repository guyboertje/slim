module Slim
module TagQuotedAttributes
  extend self

  def try(parser, scanner, attributes, options)
    return unless scanner.scan(%r~\s*(\w[:\w-]*)(==?)("|')~)

    atbe = scanner.m1
    esc = (scanner.m2 != ?=) && options[:escape_quoted_attrs]
    qc = scanner.m3
    value = String.new(qc)

    scan_re = %r~#{qc}(?= )~

    check = Progress.new(scanner)
    begin
      check.measure
      part = scanner.scan_until(scan_re)
      value.concat(part) if part
      expect = value.count(qc) % 2
    end until expect.zero? || check.stuck?

    # raise if check.stuck?

    value = value[1..-2]

    ap from: "TagQuotedAttributes", attr: atbe, value: value, rest: scanner.rest

    attributes.push [:html, :attr, atbe, [:escape, esc, [:slim, :interpolate, value]]]

    scanner.eol?
  end
end
end
