module Ekylibre
  module Ednotif
    #in/ : from Ednotif to Ekylibre transcoding
    #out/ : from Ekylibre to Ednotif transcoding

    class << self
      def root
        Ekylibre.root.join('plugins', 'ednotif', 'lib', 'ekylibre', 'ednotif')
      end

      def transcoding_dir
        root.join('transcoding')
      end

      def in_transcoding_dir
        transcoding_dir.join('in')
      end

      def out_transcoding_dir
        transcoding_dir.join('out')
      end

      def import_dir
        root.join('resources')
      end

      def schema_url
        'http://idele.fr/XML/Schema/'
      end
    end
  end
end

