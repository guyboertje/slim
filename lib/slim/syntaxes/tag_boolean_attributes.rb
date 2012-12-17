module Slim
module TagBooleanAttributes
  extend self

  def try(parser, scanner, attributes, memo)
    return false unless memo[:wrapped_attributes]
    return false unless atbe = scanner.scan(%r~\s*(\w[:\w-]*)(?=\s|\r?\n)~)

    attributes.push [:html, :attr, atbe.strip, [:slim, :attrvalue, false, 'true']]
    true
  end
end
end
