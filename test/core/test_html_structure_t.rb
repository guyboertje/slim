require 'helper'

class TestSlimHtmlStructure < TestSlim

  def test_render_with_text_block_with_subsequent_markup
      source = %q{
  h1
    |
      Lorem ipsum dolor sit amet, consectetur adipiscing elit.
  p Some more markup
  }

      assert_html '<h1>Lorem ipsum dolor sit amet, consectetur adipiscing elit.</h1><p>Some more markup</p>', source
    end

  def test_nested_text_with_nested_html_one_same_line2
    source = %q{
p
 |This is line one.
   This is line two.
 span.bold This is a bold line in the paragraph.
 |  This is more content.
}

    assert_html "<p>This is line one.\n This is line two.<span class=\"bold\">This is a bold line in the paragraph.</span> This is more content.</p>", source
  end


  def test_render_with_text_block_with_trailing_whitespace
    source = %q{
' this is
  a link to
a href="link" page
}

    assert_html "this is\na link to <a href=\"link\">page</a>", source
  end



# ruby -I"lib:lib:test/core" test/core/test_html_structure.rb --seed 27793

end
