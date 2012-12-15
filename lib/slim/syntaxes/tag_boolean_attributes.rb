module Slim
module TagBooleanAttributes
  extend self

  def try(parser, scanner, attributes, memo)
    return unless memo[:wrapped_attributes]
    return unless atbe = scanner.scan(%r~\s*(\w[:\w-]*)(?=\s|\r?\n)~)
    
    ap from: "TagBooleanAttributes", attr: atbe, quoted: 'true'

    attributes.push [:html, :attr, atbe, [:slim, :attrvalue, false, 'true']]
    scanner.eol?
  end
end
end
