#!/usr/bin/env ruby

$:.unshift(File.join(File.dirname(__FILE__), '..', 'lib'), File.dirname(__FILE__))

require 'slim'
require 'ruby-prof'
require 'awesome_print'

content = File.read(File.dirname(__FILE__) + '/view2.slim')
# engine = Slim::Engine.new

# # 100.times { engine.call(content) }
# engine.call(content)

parser = Slim::Parser.new
# parser.call(content)

# PerfTools::CpuProfiler.start("~/tmp/slim_parser") do
#   10.times { parser.call(content)}
# end
RubyProf.start

# 10.times { parser.call(content)}
parser.call(content)

result = RubyProf.stop
# result.eliminate_methods!([/String#\[\]/, /Regexp#===/])

printer = RubyProf::MultiPrinter.new(result)
printer.print(:path => ".", :profile => "pars_mine")
