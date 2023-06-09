# frozen_string_literal: true

require_relative 'ednotif/in_transcoder'
require_relative 'ednotif/out_transcoder'

module Ekylibre
  module Ednotif
    EDNOTIF_VERSION = '1.00'
    # in/ : from Ednotif to Ekylibre transcoding
    # out/ : from Ekylibre to Ednotif transcoding
    DIRECTORY_WSDL = 'http://ws-directory.fiea.fr/wsannuaire/WsAnnuaire?wsdl'
    TEST_DIRECTORY_WSDL = 'http://wstest-directory.fiea.fr/wsannuaire/WsAnnuaire?wsdl'

    # 9 is for national webservices
    CODE_SITE_VERSION = 9
    SERVICE_NAME = 'IpBNotif'
    APPLICATION_LABEL = 'Ekylibre'

    class << self
      def root
        Ekylibre::Ednotif::Engine.root
      end

      def transcoding_dir
        root.join('lib', 'ekylibre', 'ednotif', 'transcoding')
      end

      def in_transcoding_dir
        transcoding_dir.join('in')
      end

      def out_transcoding_dir
        transcoding_dir.join('out')
      end

      def import_dir
        root.join('lib', 'ekylibre', 'ednotif', 'resources')
      end

      def schema_definition
        import_dir.join('IpBNotif_v1.xsd') if EDNOTIF_VERSION == 1
      end

      def schema_url
        'http://www.idele.fr/XML/Schema/'
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

require_relative 'ednotif/engine' if defined?(::Rails)
require_relative 'ednotif/ext_navigation' if defined?(::Rails)
