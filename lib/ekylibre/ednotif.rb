module Ekylibre
  module Ednotif
    EDNOTIF_VERSION = '1.00'
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

      def schema_definition
        import_dir.join('IpBNotif_v1.xsd') if EDNOTIF_VERSION == 1
      end

      def schema_url
        'http://idele.fr/XML/Schema/'.freeze
      end

      def transcoding_manifest
        Ekylibre::Tenant.private_directory.join('plugins', 'ednotif', 'manifest.log')
      end

      def transcoding_routines
        transcoding_dir.join('routines.yml')
      end

      # return a Nokogiri document
      def base64_zip_to_xml(message)
        xml = nil
        Zip::File.open_buffer(::Base64.decode64(message)) do |f|
          xml = Nokogiri::XML f.first.get_input_stream.read
        end
        xml
      end
    end
  end
end