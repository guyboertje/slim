require 'helper'

class TestSlimHtmlStructureT < TestSlim
  
  def test_thread_options
    source = %q{p.test}

    assert_html '<p class="test"></p>', source
    assert_html "<p class='test'></p>", source, :attr_wrapper => "'"

    Slim::Engine.with_options(:attr_wrapper => "'") do
      assert_html "<p class='test'></p>", source
      assert_html '<p class="test"></p>', source, :attr_wrapper => '"'
    end

    assert_html '<p class="test"></p>', source
    assert_html "<p class='test'></p>", source, :attr_wrapper => "'"
  end
# ruby -I"lib:lib:test/core" test/core/test_html_structure_t.rb --seed 27793

end
