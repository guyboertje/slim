module Slim
class CodeFinder

  def initialize
    @part_re = /[\{\[\(]/
    @delim_map = Hash[?(,?),?[,?],?{,?}]
    @delim_close_map = {}
    @delim_map.each do |k,v|
      @delim_close_map[k] = /#{Re.quote(v)}/m
    end
    @esc_double_re = /\\"/
    @esc_single_re = /\\'/
    @dbl_single = /["']/
  end

  def reset(line)
    @found = false
    @code = nil
    @parts = line.partition(@part_re)

    @first = @parts[0]
    @delim = @parts[1]
    @rest = @parts[2]

    if @delim.empty?
      @code = line
      @found = true
    else
      @delim_close = @delim_map[@delim]
      analyse
    end
  end

  def enclosed_by_delim?
    @first.empty? && @delim_close && @rest.end_with?(@delim_close + ' ')
  end

  def strip_delim_ws
    val = code.strip
    if val.start_with?(@delim) && val.end_with?(@delim_close)
      val[1, val.size - 2]
    else
      val
    end
  end

  def done?
    @found
  end

  def code
    @code ||= @parts.join
  end

  def add(part)
    @rest.concat(part)
    analyse
    @found
  end

  def analyse
    return if @rest.empty?
    net_delims = (1 + @rest.count(@delim) - @rest.count(@delim_close)) == 0

    # temp = @rest.gsub(@esc_double_re,'').gsub(@esc_single_re, '')
    # b, m, e = temp.partition(@dbl_single)
    b, m, e = @rest.partition(@dbl_single)
    
    # ap from: "CodeFinder analyse", delim_close: delim_close, rest: rest, temp: temp, b: b, m: m, e: e

    if m.empty? && e.empty? && net_delims
      # no opening quotes and there is a net match of delims
      @found = true
      return
    end     

    if !m.empty? && e.index(m) && net_delims
      # there is an opening quote, a closing quote and a net match of delims
      e.reverse!
      if e.index(@delim_close) < e.index(m)
        # the closing delim occurs after the closing quote (e is reversed)
        @found = true
        return
      end
    end
  end

end
end
