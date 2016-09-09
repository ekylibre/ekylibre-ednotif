# The Abaci-inspired nomenclature for YAML
# Example:
# [nomenclature][table][item]
# YamlNomen[:outgoing]['varieties-bos_taurus']['bos_taurus_abondance'] => 12

module YamlNomen
  autoload :Table, 'yaml_nomen/table'
  autoload :Nomenclature, 'yaml_nomen/nomenclature'

  mattr_accessor :set do
    {}.with_indifferent_access
  end

  class << self
    def load(name, files)
      set[name] = YamlNomen::Nomenclature.new(files)
      set
    end

    def [](name)
      set[name]
    end
  end
end
