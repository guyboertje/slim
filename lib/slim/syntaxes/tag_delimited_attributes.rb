module Slim
module TagDelimitedAttributes
  extend self

  def try(parser, scanner, memo)
    return if memo[:wrapped_attributes]
    return unless delim_open = scanner.shift_delim

    delim_close = delim_map[delim_open]
    end_re = /#{Re.quote(delim_close)}/m
    part, line, expect = "", " ", 1

    check = Progress.new(scanner)
    begin
      check.measure
      part = scanner.scan_until(end_re)
      if (part.nil? || part.empty?) && !expect.zero?
        raise "expecting closing ]"
      end
      line.concat(part.squeeze(' '))
      expect += line.count(delim_open)
      expect -= line.count(delim_close)
    end until expect.zero? || check.stuck?

    line.chomp!(delim_close) # ignore last closing delimiter
    if line.empty? || check.stuck?
      raise "expected to have delimited attributes"
    end
    line.gsub!(/\r?\n/, ' ') # behave like a single line
    line.concat(' ')

    parser.set_temp_scanner(line)
    memo[:wrapped_attributes] = true
    
    false
  end

  def delim_map
    @h1 ||= Hash[?(,?),?[,?],?{,?}]
  end

end
end
