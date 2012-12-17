module Slim
module TagCodeAttributes
  extend self

  def try(parser, scanner, attributes, options)

    return false unless scanner.scan(%r~\s*(\w[:\w-]*)(==?)~)

    atbe = scanner.m1
    esc = (scanner.m2 != ?=) && options[:escape_quoted_attrs]

    scan_re = %r~ |(?=\r?\n)~
    monitor = Progress.new(scanner)
    monitor.measure
    part = scanner.scan_until(scan_re)
    raise "No part" unless part

    finder = CodeFinder.new(part)
    until finder.done? || monitor.stuck? do

      monitor.measure
      part = scanner.scan_until(scan_re)
      if part
        finder.add(part)
      else
        break
      end
    end

    raise "No code found" unless finder.done?

    value = finder.code
    
    scanner.backup if value.end_with?(' ')

    if finder.enclosed_by_delim?
      value = value[1,value.size - 3]
    end

    ap from: "TagCodeAttributes", attr: atbe, value: value, rest: scanner.rest

    attributes.push [:html, :attr, atbe, [:slim, :attrvalue, esc, value]]

    true
  end
end
end
