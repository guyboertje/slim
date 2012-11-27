class HtmlComment

  def self.try(scanner)
    if comment = scanner.input.scan(%r{/!( ?)})
      self.new(scanner, comment).call
    else
      false
    end
  end

  def initialize(scanner, comment)
    @scanner = scanner
    @indent = scanner.current_indent
    @out = [:multi]
    @result = [:html, :comment, [:slim, :text, @out]]
  end

  def scanner
    @scanner
  end

  def input
    scanner.input
  end

  def call
    if part = scanner.shift_text
      @out << [:slim, :interpolate, part]
    end
    scanner.line_end(false)
    min_indent = scanner.current_indent.succ
    if block = input.scan(%r{(\n* {#{min_indent},}.*\n+)*})
      # "\n   Another comment\n     \n   Another comment\n\n   Another comment\n"
      empty_lines = []
      rest = input.rest
      input.string = block
      until input.eos? do
        if line_end(false)
          empty_lines << ?\n
        end
        if line = input.shift_text
          
          line.lstrip!
          if line.empty?
            empty_lines << ?\n
          else
            if !empty_lines.empty?
              @out << [:slim, :interpolate, empty_lines.join('')]
              empty_lines.clear
            end
            @out << [:slim, :interpolate, (text_indent ? "\n" : '') + (' ' * offset) + line]
          end
        end
      end
      input.string = rest
    end
    @scanner.build @result
    true
  end
  
end
