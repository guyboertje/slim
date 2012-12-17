module Slim
  class Progress

    def initialize(scanner)
      @scanner = scanner
    end

    def measure
      @pos = @scanner.position
    end

    def stuck?
      @scanner.position == @pos
    end

    def progress?
      if @pos.nil?
        measure
        true
      else
        was = @pos
        measure
        @scanner.position > was
      end
    end

    def last
      @pos
    end
    
  end
end
