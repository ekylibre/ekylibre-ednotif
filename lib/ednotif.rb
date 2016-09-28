module Ednotif
  EDNOTIF_VERSION = '1.00'
  DIRECTORY_WSDL = 'http://ws-directory.fiea.fr/wsannuaire/WsAnnuaire?wsdl'.freeze
  TEST_DIRECTORY_WSDL = 'http://wstest-directory.fiea.fr/wsannuaire/WsAnnuaire?wsdl'.freeze

  # 9 is for national webservices
  CODE_SITE_VERSION = 9
  SERVICE_NAME = 'IpBNotif'
  APPLICATION_LABEL = 'Ekylibre'

  class << self
    def build

      # plateforme de test
      # https://wwwdev.cmre.fr:443/wsguichet/WsGuichet

      options = {
          wsdl: 'http://wstest1-directory.fiea.fr:80/wsannuaire/WsAnnuaire?wsdl',
          # ssl_verify_mode: :none,
          # env_namespace: :soapenv,
          namespace_identifier: 'tk',
          namespaces: {
              # 'xmlns:tk': 'http://www.fiea.org/tk/',
              'xmlns:typ': 'http://www.fiea.org/types/'
          },
          # open_timeout: 15,
          # read_timeout: 15,
          log: true,
          logger: Rails.logger
      }

      binding.pry

      client = Savon.client options

      res = client.call(:tk_get_url,
                        message_tag: "#{:tk_get_url.to_s.camelize(:lower)}Request",
                        response_parser: :nokogiri,
                        message: {
                            'tk:ProfilDemandeur': {
                                'typ:Entreprise': 'E010',
                                'typ:Application': 'Ekylibre'
                            },
                            'tk:VersionPK': {
                                'typ:NumeroVersion': 1.00,
                                'typ:CodeSiteVersion': 9,
                                'typ:NomService': 'IpBNotif',
                                'typ:CodeSiteService': 9
                            }
                        })

      res
      binding.pry

    end
    def validate_message(xml)
      doc = Nokogiri::XML xml
      schema = Nokogiri::XML::Schema Ekylibre::Ednotif.schema_definition.open
      schema.validate(doc).errors
    end
  end
end