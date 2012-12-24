module Slim
module TagCodeAttributes
  extend self

  def code_re
    @cre ||= %r~\s*(\w[:\w-]*)(==?)~
  end

  def try(parser, scanner, attributes, escape_quoted_attrs)

    return false unless scanner.scan(code_re)

    atbe = scanner.m1
    esc = !!escape_quoted_attrs || true
    esc = false if scanner.m2 == '=='

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

    value = finder.enclosed_by_delim? ? value[1,value.size - 3] : value.strip

    parser.syntax_error!('Invalid empty attribute') if value.empty?

    attributes.push [:html, :attr, atbe, [:slim, :attrvalue, esc, value]]

    true
  end
end
end
