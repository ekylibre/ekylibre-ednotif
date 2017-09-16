module YamlNomen
  class Table
    def initialize(set)
      @rows = set
    end

    def [](item)
      @rows[item]
    end

    alias find []
  end
end
