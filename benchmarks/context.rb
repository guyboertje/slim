Request = Struct.new :protocol, :host_with_port

class Context
  def header
    'Colors'
  end

  def item
    [ { :name => 'red',   :current => true,  :url => '#red'   },
      { :name => 'green', :current => false, :url => '#green' },
      { :name => 'blue',  :current => false, :url => '#blue'  } ]
  end

  def t(*)
    "abvibviqjbvpiqjfbvpqijfbvpqijfbpqijfbpvqijbvpqijbvpqijbvpqijbfvpqijfbvpqijbfv"
  end

  def request
    @req ||= Request.new("http://", "localhost:3000")
  end
  def asset_path(*)
    'asdafafs'
  end
  def stylesheet_link_tag(*)
    "adfadfga"
  end
  def javascript_include_tag(*)
    "ywrthsthwthr"
  end
  def yeild(*)
    "rqeuirquirqeuivnqvkqwrvjqwrkvjqkjv"
  end
  def csrf_meta_tag(*)
    "dnvjwdnwodjncwodncwodcnowc"
  end
  def render(*)
    "div class=\"utf-8\""
  end
  def action_name(*)
    "agargvavarvav"
  end
  def controller_name
    "adfgadfgadfg"
  end

end
