module Slim
module TagSplatAttributes
  extend self

  def try(parser, scanner, attributes)
    
    return unless splat = scanner.scan(%r~\s*\*(\S)~)

    code = scanner.m1
    expect = code[/\(|\{/] ? 1 : 0

    openings, closings = "({", "})"
    scan_re = %r~ |(?=\r?\n)~

    begin
      part = scanner.scan_until(scan_re)
      if (part.nil? || part.empty?) && !expect.zero?
        raise "expecting closing ) or }"
      end
      if part
        code.concat(part)
        expect += part.count(openings)
        expect -= part.count(closings)
      else
        break
      end
    end until expect.zero?

    ap from: "TagSplatAttributes", code: code

    attributes.push [:slim, :splat, code.strip]
  end
end
end
