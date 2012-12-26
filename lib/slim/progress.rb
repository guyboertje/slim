module Slim
  class Progress

    attr_reader :scanner

    def reset(scanner)
      @scanner = scanner
      @pos = nil
    end

    def measure
      @pos = scanner.position
    end

    def stuck?
      scanner.position == @pos
    end

    def progress?
      if @pos.nil?
        measure
        true
      else
        was = @pos
        measure
        scanner.position > was
      end
    end

    def last
      @pos
    end
    
  end
end
