module Slim
module Tag
  extend self

  def try(parser, scanner, tag_re)
    unless tag_line = scanner.scan(tag_re)
      return true
    end
    
    tag = parser.shortcut_sub(scanner.m1)

    ap from: "Tag", tag_line: tag_line, tag: tag, rest: scanner.m3

    attributes = [:html, :attrs]

    parser.build [:html, :tag, tag, attributes]

    if scanner.check_lf
      true # done
    else
      parser.push attributes
      false
    end

  end

  # def parse_attributes(parser, scanner, ss, attributes)
  #   attributes = [:html, :attrs]
  #   while shortcut = ss.scan(parser.shortcut_re) do
  #     sub, val = parser.shortcut_lookup(ss[1]), ss[2]
  #     attributes.push [:html, :attr, sub, [:static, val]]
  #   end
  #   delim = ss.scan(delim_re)
  #   if delimiter = delim_map.fetch(delim, nil)

  #   end


  #   until ss.eos? do
  #     try_splats(ss) ||

  #   end

  # end

  # def delim_map
  #   @h1 ||= Hash[?(,?),?[,?],?{,?}]
  # end

  # def delim_re
  #   @red || Re.new delim_map.keys.map{|k| Re.quote(k)}.join(?|)
  # end

  # def boolean_attr_regex(delim = nil)
  #   %r{#{attr_name}#{Re.quote(delim)}   }
  # end
end
end
