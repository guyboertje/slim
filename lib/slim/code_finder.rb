module Slim
class CodeFinder

  def initialize(line)
    @parts = line.partition(/[\{\[\(]/)
    if delim.empty?
      @code = line
    else
      @code = nil
      analyse
    end
  end

  def enclosed_by_delim?
    first.empty? && delim_close && rest.end_with?(delim_close + ' ')
  end

  def strip_delim_ws
    val = @code.strip
    if val.start_with?(delim) && val.end_with?(delim_close)
      val[1, val.size - 2]
    else
      val
    end
  end


  def first() @parts[0]; end

  def delim() @parts[1]; end

  def rest()  @parts[2]; end

  def done?() !!@code; end

  def code() @code; end

  def add(part)
    rest.concat(part)
    analyse
    done?
  end

  def analyse
    return if rest.empty?
    temp = rest.gsub(/\\"/,'').gsub(/\\'/, '')
    b, m, e = temp.partition(/["']/)
    
    # ap from: "CodeFinder analyse", delim_close: delim_close, rest: rest, temp: temp, b: b, m: m, e: e

    if m.empty? && e.empty? && (net_delim_count == 0)
      # no opening quotes and there is a net match of delims
      @code = @parts.join
      return
    end

    if !m.empty? && e.index(m) && (net_delim_count == 0)
      # there is an opening quote, a closing quote and a net match of delims 
      tmp = e.reverse
      qpos = tmp.index(m)
      dpos = tmp.index(delim_close)
      # ap from: "CodeFinder analyse", tmp: tmp, dpos: dpos, qpos: qpos
      if dpos < qpos
        # the closing delim occurs after the closing quote (e is reversed)
        @code = @parts.join
        return
      end
    end
  end

  def net_delim_count
    1 + rest.count(delim) - rest.count(delim_close)
  end

  def delim_map
    @h1 ||= Hash[?(,?),?[,?],?{,?}]
  end

  def delim_close
    @dc1 ||= delim_map[delim]
  end

  def delim_close_re
    @re1 ||= /#{Re.quote(delim_close)}/
  end

end
end
