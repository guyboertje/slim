require 'helper'

class TestSlimHtmlStructure < TestSlim

  def test_multiline_attributes_with_text_on_same_line
    source = %q{
p<id="marvin"
  class="martian"
 data-info="Illudium Q-36"> THE space modulator
}
    Slim::Parser::DELIMITERS.each do |k,v|
      str = source.sub('<',k).sub('>',v)
      assert_html '<p class="martian" data-info="Illudium Q-36" id="marvin">THE space modulator</p>', str
    end
  end

# ruby -I"lib:lib:test/core" test/core/test_html_structure.rb --seed 27793

end
