require 'helper'

class TestSlimHtmlStructureT < TestSlim

  def test_html_ruby_attr_escape
    source = %q{
p id=('&'.to_s) class==('&amp;'.to_s)
}

    assert_html '<p class="&amp;" id="&amp;"></p>', source
  end

# ruby -I"lib:lib:test/core" test/core/test_html_structure_t.rb --seed 27793

end
