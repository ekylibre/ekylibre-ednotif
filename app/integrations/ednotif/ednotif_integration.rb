module Ednotif
  mattr_reader :default_options do
    {
        globals: {
            strip_namespaces: true,
            convert_response_tags_to: lambda { |tag| tag.snakecase.to_sym },
        },
        locals: {
            advanced_typecasting: true
        }
    }
  end

  class EdnotifIntegration < ActionIntegration::Base
    auth :check do
      parameter :enterprise
      parameter :login
      parameter :password
    end

    calls :get_list
    calls :get_urls
    calls :authenticate

    ##
    # get_list: fournir l’inventaire des bovins d’une exploitation entre deux dates. L’inventaire peut être complété par la liste des boucles disponibles.
    # @param [string] token: token from reswel, length: 50
    # @param [string] farm_country_code: Toujours 'FR'. length: 2
    # @param [string] farm_number: Numéro d'exploitation française. length: 8
    # @param [date] start_date: Date début de période de présence des bovins
    # @param [date] end_date: Date fin de période de présence des bovins
    # @param [Object] stock: Indique si le stock de boucles doit être retourné
    def get_list(parameters = {})
      # get hash with ekylibre data

      parameters[:options] ||= {}
      parameters[:message] ||= {}

      # integration = fetch

      fail 'Missing WSDL' unless parameters[:options].key?(:wsdl)

      # fail 'Missing token' unless options.key?(:token)

      # typeExploitationFrancaisePK
      # fail 'invalid cattling number' unless dataset[:farm_number] =~ /[0-9]{8}/

      #
      # message = {
      #     'sch:JetonAuthentification': '924ffe40-547f-458e-a06e-f5c9145ed795',
      #     'sch:Exploitation': {
      #         'sch:CodePays': 'FR',
      #         'sch:NumeroExploitation': dataset[:farm_number]
      #     },
      #     'sch:DateDebut': dataset[:start_date],
      #     'sch:StockBoucles': dataset[:get_stock] ? 1 : 0
      # }

      parameters[:options].reverse_merge!(::Ednotif.default_options).merge!({
                                                                                namespace_identifier: 'sch',
                                                                                namespaces: {
                                                                                    'xmlns:sch': 'http://www.idele.fr/XML/Schema/'
                                                                                }
                                                                            })

      message = Ekylibre::Ednotif::OutTranscoder.convert parameters[:message]

      call_savon(:ip_b_get_inventaire, parameters[:options], message) do |r|
        r.success do

          nested = r.body[r.body.keys.first]

          # reject namespaces definition
          nested.reject! { |k, _| k =~ /\A@.*\z/ }

          doc = Ekylibre::Ednotif::InTranscoder.convert(nested)

          if doc[:standard_response][:result]
            parser = Nori.new strip_namespaces: true, convert_tags_to: lambda { |tag| tag.snakecase.to_sym }, advanced_typecasting: true
            # because \n special chars are escaped by default, but it must be considered during base64 decoding.
            embedded_xml = Ekylibre::Ednotif.base64_zip_to_xml doc[:particular_response][:embedded_document].gsub(/\\n/, "\n")
            hashed = parser.parse(embedded_xml.to_xml)

            # :message_ip_b_notif_get_inventaire + reject @namespaces definitions
            nested = hashed[hashed.keys.first].reject { |k, _| k =~ /\A@.*\z/ }

            doc = Ekylibre::Ednotif::InTranscoder.convert(nested)
          else
            r.error YamlNomen[:incoming][:error_codes][doc[:standard_response][:issue][:code]]
          end

          # hash format
          doc

        end
      end
    end

    # Current callers mechanism can't support nested callers so we consider pinging directory as a success connection.
    # Real user authentication has to be managed later.
    def check(integration = nil)
      integration = fetch integration

      get_urls(integration)
    end

    # force: To force authentication process even if a token is already registered
    def self.authenticate_and_do(logger = nil, force = false, &block)
      integration ||= fetch
      binding.pry


      # unless integration.parameters['token'] || force

      get_urls.execute(logger) do |c|
        c.success do |response|
          integration ||= fetch

          # TODO change this
          logger.state :success
          logger.save!

          integration.parameters['authentication_wsdl'] = response[:particular_response][:authentication_wsdl]
          integration.parameters['business_wsdl'] = response[:particular_response][:business_wsdl]

          authenticate(wsdl: integration.parameters['authentication_wsdl']).execute(logger) do |auth_c|
            auth_c.success do |auth_response|
              integration ||= fetch

              binding.pry
              integration.parameters['token'] = auth_response[:token]
              integration.save!

              yield block if block_given?
            end

            auth_c.error :failed_connection do
              integration ||= fetch

              logger.state :error
              logger.save!

              integration.creator.notify 'failed_connection', {}, {target: auth_c, level: :error}
            end

          end
        end

        # could occurs if enterprise code is wrong
        c.error :missing_wsdl do
          #retry ?
        end

        c.error do
          #retry ?
        end
      end

      # end
    end

    def authenticate(parameters = {})
      integration = fetch

      options = ::Ednotif.default_options.merge(
          globals: {
              namespace_identifier: 'tk',
              namespaces: {
                  'xmlns:typ': 'http://www.fiea.org/types/'
              },
              wsdl: parameters['wsdl']
          }
      )
      binding.pry

      message = {
          'tk:Identification': {
              'typ:UserId': integration.parameters['login'],
              'typ:Password': integration.parameters['password'],
              'typ:Profil': {
                  'typ:Entreprise': integration.parameters['enterprise'],
                  'typ:Application': Ednotif::APPLICATION_LABEL
              }
          }
      }

      call_savon(:tk_create_identification, options, message) do |r|
        r.success do
          nested = r.body[:tk_create_identification_response].reject { |k, _| k =~ /\A@.*\z/ }
          doc = Ekylibre::Ednotif::InTranscoder.convert(nested)

          binding.pry
          if doc[:standard_response][:result]
            doc
          else
            r.error YamlNomen[:incoming][:error_codes][doc[:standard_response][:issue][:code]]
          end

        end

        r.error do
          binding.pry
        end
      end

    end

    def get_urls(integration = nil)
      # retrieve integration unless it is already supplied (on check_connection step)
      integration ||= fetch

      options = ::Ednotif.default_options.merge(
          globals: {
              namespace_identifier: 'tk',
              namespaces: {
                  'xmlns:typ': 'http://www.fiea.org/types/'
              },
              wsdl: ::Ednotif::TEST_DIRECTORY_WSDL
          })

      message = {
          'tk:ProfilDemandeur': {
              'typ:Entreprise': integration.parameters['enterprise'],
              'typ:Application': Ednotif::APPLICATION_LABEL
          },
          'tk:VersionPK': {
              'typ:NumeroVersion': Ednotif::EDNOTIF_VERSION,
              'typ:CodeSiteVersion': Ednotif::CODE_SITE_VERSION,
              'typ:NomService': Ednotif::SERVICE_NAME,
              'typ:CodeSiteService': Ednotif::CODE_SITE_VERSION
          }
      }
      call_savon(:tk_get_url, options, message) do |r|
        r.success do
          nested = r.body[:tk_get_url_response].reject { |k, _| k =~ /\A@.*\z/ }
          doc = Ekylibre::Ednotif::InTranscoder.convert(nested)
          binding.pry
          if doc[:standard_response][:result]
            unless doc.key?(:particular_response) && doc[:particular_response][:business_wsdl] && doc[:particular_response][:authentication_wsdl]
              r.error :missing_wsdl
            end
              doc
          else
            r.error YamlNomen[:incoming][:error_codes][doc[:standard_response][:issue][:code]]
          end

        end
      end
    end
  end
end
