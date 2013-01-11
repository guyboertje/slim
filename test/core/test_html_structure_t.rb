require 'helper'

class TestSlimHtmlStructureT < TestSlim
  
  def test_render_html_comments
    source = %q{/! Comment
body
  /! Another comment
     with multiple lines
  p Hello!
  /!
      First line determines indentation

      of the comment
}

    html = 
%q{<!--Comment-->
<body>
  <!--Another comment
  with multiple lines-->
  <p>Hello!</p>
  <!--First line determines indentation
  
  of the comment-->
</body>
}
    assert_html html, source
  end
# ruby -I"lib:lib:test/core" test/core/test_html_structure_t.rb --seed 27793

end
