module Slim
module TagCodeAttributes
  extend self

  def try(parser, scanner, attributes, options)

    return unless scanner.scan(%r~\s*(\w[:\w-]*)(==?)(?=(\s*\w))~)

    atbe = scanner.m1
    esc = (scanner.m2 != ?=) && options[:escape_quoted_attrs]
    value = String.new

    expect, openings, closings = 0, "({[", "]})"

    scan_re = %r~ |(?=\r?\n)~
    begin
      part = scanner.scan_until(scan_re)
      if part
        value.concat(part) unless part.nil?
        expect += part.count(openings)
        expect -= part.count(closings)
      else
        break
      end
    end until expect.zero?

    ap from: "TagCodeAttributes", attr: atbe, esc: esc, value: value

    attributes.push [:html, :attr, atbe, [:slim, :attrvalue, esc, value]]

    scanner.eol?
  end
end
end
