module YamlNomen
  class Nomenclature
    def initialize(files)
      @tables = {}.with_indifferent_access

      files.each do |file|
        @tables[File.basename(file, '.yml').to_sym] = YamlNomen::Table.new(YAML.load_file(file))
      end
    end

    def [](item)
      @tables[item]
    end

    alias find []
  end
end