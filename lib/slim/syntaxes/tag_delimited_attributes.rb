module Slim
module TagDelimitedAttributes
  extend self

  def try(parser, scanner, memo)
    return if memo[:wrapped_attributes]
    return unless delim_open = scanner.scan(delim_re)

    delim_close = delim_map[delim_open]
    end_re = /#{Re.quote(delim_close)}/m
    part, line, expect = "", " ", 1

    begin
      part = scanner.scan_until(end_re)
      if (part.nil? || part.empty?) && !expect.zero?
        raise "expecting closing ]"
      end
      line.concat(part.squeeze(' '))
      expect += line.count(delim_open)
      expect -= line.count(delim_close)
    end until expect.zero?

    line.chomp!(delim_close) # ignore last closing delimiter
    if line.empty?
      raise "expected to have delimited attributes"
    end
    scanner.liner.advance(line.count(?\n))
    rest = scanner.shift_upto_lf
    line.gsub!(/\r?\n/, ' ') # behave like a single line
    line.concat(' ').concat(rest)

    temp_scanner = Scanner.new(line, parser)
    parser.set_temp_scanner(temp_scanner)
    memo[:wrapped_attributes] = true
    
    false
  end

  def delim_map
    @h1 ||= Hash[?(,?),?[,?],?{,?}]
  end

  def delim_re
    Re.new( delim_map.keys.map{|k| Re.quote(k)}.join(?|) )
  end
end
end
