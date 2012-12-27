module Slim
class CodeFinder

  attr_reader :code

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
    @parts = line.partition(@part_re)

    @first = @parts[0]
    @delim = @parts[1]
    @rest = @parts[2]

    if @delim.empty?
      @code = line
    else
      @delim_close = @delim_map[@delim]
      @code = nil
      analyse
    end
  end

  def enclosed_by_delim?
    @first.empty? && @delim_close && @rest.end_with?(@delim_close + ' ')
  end

  def strip_delim_ws
    val = @code.strip
    if val.start_with?(@delim) && val.end_with?(@delim_close)
      val[1, val.size - 2]
    else
      val
    end
  end

  def done?
    !!@code
  end

  def add(part)
    @rest.concat(part)
    analyse
    done?
  end

  def analyse
    return if @rest.empty?
    net_delims = (1 + @rest.count(@delim) - @rest.count(@delim_close)) == 0
    
    temp = @rest.gsub(@esc_double_re,'').gsub(@esc_single_re, '')
    b, m, e = temp.partition(@dbl_single)
    
    # ap from: "CodeFinder analyse", delim_close: delim_close, rest: rest, temp: temp, b: b, m: m, e: e

    if m.empty? && e.empty? && net_delims
      # no opening quotes and there is a net match of delims
      @code = @parts.join
      return
    end     

    if !m.empty? && e.index(m) && net_delims
      # there is an opening quote, a closing quote and a net match of delims 
      tmp = e.reverse
      qpos = tmp.index(m)
      dpos = tmp.index(@delim_close)
      # ap from: "CodeFinder analyse", tmp: tmp, dpos: dpos, qpos: qpos
      if dpos < qpos
        # the closing delim occurs after the closing quote (e is reversed)
        @code = @parts.join
        return
      end
    end
  end

end
end
