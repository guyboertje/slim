module Slim
module TagSplatAttributes
  extend self

  def try(parser, scanner, attributes)
    
    return false unless splat = scanner.scan(%r~\s*\*~)

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

    code = finder.code
    
    scanner.backup if code.end_with?(' ')

    attributes.push [:slim, :splat, code.strip]
    true
  end
end
end
