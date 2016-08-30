require 'mechanize'

module Ekylibre
  module Ednotif
    class Fetcher
      class << self

        def import_dir
          Ekylibre.root.join('plugins', 'ednotif', 'lib', 'ekylibre', 'ednotif', 'resources')
        end

        def schema_url
          'http://idele.fr/XML/Schema/'
        end

        def fetch
          agent = Mechanize.new

          links = agent.get(schema_url).links_with(text: /(.*).(xsd|XSD)$/)

          links.each { |link| agent.click(link).save! import_dir.join(link.text) }

        end
      end
    end
  end
end

