require 'helper'

class TestSlimHtmlStructureT < TestSlim


  def test_hash_call_in_delimited_attribute_with_ruby_evaluation_3
    source = %q{
p(id=[hash[:a] + hash[:a]]) Test it
}

    assert_html '<p id="The letter aThe letter a">Test it</p>', source
  end

# ruby -I"lib:lib:test/core" test/core/test_html_structure_t.rb --seed 27793

end
