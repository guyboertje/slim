module Slim
module Doctype
  extend self

  def try(parser, scanner)
    unless doctype_line = scanner.scan(%r{doctype(.*)(?=\r?\n)}i)
      return false
    end
    parser.build [:html, :doctype, scanner.m1.strip]
    true
  end
end
end
