require 'mechanize'

module Ekylibre
  module Ednotif
    class Fetcher
      class << self

        def fetch
          agent = Mechanize.new

          links = agent.get(::Ednotif.schema_url).links_with(text: /(.*).(xsd|XSD)$/)

          links.each { |link| agent.click(link).save! ::Ednotif.import_dir.join(link.text) }

        end
      end
    end
  end
end

