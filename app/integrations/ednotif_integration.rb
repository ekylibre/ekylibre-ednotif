# coding: utf-8

class EdnotifIntegration < ActionIntegration::Base
  mattr_reader :default_options do
    {
      globals: {
        strip_namespaces: true,
        convert_response_tags_to: ->(tag) { tag.snakecase.to_sym },
        raise_errors: false
      },
      locals: {
        advanced_typecasting: true
      }
    }
  end

  class ServiceError < StandardError; end

  authenticate_with :check do
    parameter :cattling_number
    parameter :enterprise
    parameter :login
    parameter :password
  end

  calls :get_inventory
  calls :create_cattle_entrance
  calls :create_cattle_exit
  calls :create_cattle_new_birth
  calls :get_urls
  calls :authenticate

  def create_cattle_entrance(parameters = {})
    parameters = parameters.deep_symbolize_keys!

    parameters[:options] ||= {}
    parameters[:message] ||= {}

    # we need to handle namespaces because business wsdl seems a bit buggy
    parameters[:options] = ::EdnotifIntegration.default_options
                                               .deep_merge(parameters[:options])
                                               .deep_merge(
                                                 globals: {
                                                   namespace_identifier: 'edn',
                                                   namespace: 'http://www.idele.fr/XML/Schema/'
                                                 }
                                               )

    transcoder = Ekylibre::Ednotif::OutTranscoder.new parameters[:message]

    unless transcoder.valid?
      r = ActionIntegration::Response.new(code: '500', body: transcoder.errors)
      r.error do
        r.error :transcoding_error
        transcoder.errors
      end
      return r
    end

    call_savon(:ip_b_create_entree, parameters[:options], transcoder.message) do |r|
      r.success do
        nested = r.body[r.body.keys.first]
        # reject namespaces definition
        nested.reject! { |k, _| k =~ /\A@.*\z/ }

        doc = Ekylibre::Ednotif::InTranscoder.convert(nested)

        if doc[:standard_response][:result]
          doc
        else
          error_code = YamlNomen[:incoming][:error_codes][doc[:standard_response][:issue][:code]]
          r.client_error error_code
          error_code
        end
      end

      r.server_error do
        r.body[:fault][:faultstring] if r.body.key?(:fault) && r.body[:fault].key?(:faultstring)
      end
    end
  end

  def create_cattle_new_birth(parameters = {})
    parameters = parameters.deep_symbolize_keys!

    parameters[:options] ||= {}
    parameters[:message] ||= {}

    # we need to handle namespaces because business wsdl seems a bit buggy
    parameters[:options] = ::EdnotifIntegration.default_options.deep_merge(parameters[:options]).deep_merge(
      globals: {
        namespace_identifier: 'edn',
        namespace: 'http://www.idele.fr/XML/Schema/'
      }
    )

    transcoder = Ekylibre::Ednotif::OutTranscoder.new parameters[:message]

    unless transcoder.valid?
      r = ActionIntegration::Response.new(code: '500', body: transcoder.errors)
      r.error do
        r.error :transcoding_error
        transcoder.errors
      end
      return r
    end

    call_savon(:ip_b_create_new_birth, parameters[:options], transcoder.message) do |r|
      r.success do
        nested = r.body[r.body.keys.first]
        # reject namespaces definition
        nested.reject! { |k, _| k =~ /\A@.*\z/ }

        doc = Ekylibre::Ednotif::InTranscoder.convert(nested)

        if doc[:standard_response][:result]
          doc
        else
          error_code = YamlNomen[:incoming][:error_codes][doc[:standard_response][:issue][:code]]
          r.client_error error_code
          error_code
        end
      end

      r.server_error do
        r.body[:fault][:faultstring] if r.body.key?(:fault) && r.body[:fault].key?(:faultstring)
      end
    end
  end

  def create_cattle_exit(parameters = {})
    parameters = parameters.deep_symbolize_keys!

    parameters[:options] ||= {}
    parameters[:message] ||= {}

    # we need to handle namespaces because business wsdl seems a bit buggy
    parameters[:options] = ::EdnotifIntegration.default_options.deep_merge(parameters[:options]).deep_merge(
      globals: {
        namespace_identifier: 'edn',
        namespace: 'http://www.idele.fr/XML/Schema/'
      }
    )

    transcoder = Ekylibre::Ednotif::OutTranscoder.new parameters[:message]

    unless transcoder.valid?
      r = ActionIntegration::Response.new(code: '500', body: transcoder.errors)
      r.error do
        r.error :transcoding_error
        transcoder.errors
      end
      return r
    end

    call_savon(:ip_b_create_sortie, parameters[:options], transcoder.message) do |r|
      r.success do
        nested = r.body[r.body.keys.first]
        # reject namespaces definition
        nested.reject! { |k, _| k =~ /\A@.*\z/ }

        doc = Ekylibre::Ednotif::InTranscoder.convert(nested)

        if doc[:standard_response][:result]
          doc
        else
          error_code = YamlNomen[:incoming][:error_codes][doc[:standard_response][:issue][:code]]
          r.client_error error_code
          error_code
        end
      end

      r.server_error do
        r.body[:fault][:faultstring] if r.body.key?(:fault) && r.body[:fault].key?(:faultstring)
      end
    end
  end

  ##
  # get_inventory: fournir l’inventaire des bovins d’une exploitation entre deux dates. L’inventaire peut être complété par la liste des boucles disponibles.
  def get_inventory(parameters = {})
    parameters = parameters.deep_symbolize_keys!

    parameters[:options] ||= {}
    parameters[:message] ||= {}

    # we need to handle namespaces because business wsdl seems a bit buggy
    parameters[:options] = ::EdnotifIntegration.default_options.deep_merge(parameters[:options]).deep_merge(
      globals: {
        namespace_identifier: 'edn',
        namespace: 'http://www.idele.fr/XML/Schema/'
      }
    )

    transcoder = Ekylibre::Ednotif::OutTranscoder.new parameters[:message]

    unless transcoder.valid?
      r = ActionIntegration::Response.new(code: '500', body: transcoder.errors)
      r.error do
        r.error :transcoding_error
        transcoder.errors
      end
      return r
    end

    call_savon(:ip_b_get_inventaire, parameters[:options], transcoder.message) do |r|
      r.success do
        nested = r.body[r.body.keys.first]

        # reject namespaces definition
        nested.reject! { |k, _| k =~ /\A@.*\z/ }

        doc = Ekylibre::Ednotif::InTranscoder.convert(nested)

        if doc[:standard_response][:result]
          parser = Nori.new strip_namespaces: true, convert_tags_to: ->(tag) { tag.snakecase.to_sym }, advanced_typecasting: true
          # because \n special chars are escaped by default, but it must be considered during base64 decoding.
          embedded_xml = Ekylibre::Ednotif.base64_zip_to_xml doc[:particular_response][:embedded_document].gsub(/\\n/, "\n")
          hashed = parser.parse(embedded_xml.to_xml)

          # :message_ip_b_notif_get_inventaire + reject @namespaces definitions
          nested = hashed[hashed.keys.first].reject { |k, _| k =~ /\A@.*\z/ }

          doc = Ekylibre::Ednotif::InTranscoder.convert(nested)
          doc
        else
          error_code = YamlNomen[:incoming][:error_codes][doc[:standard_response][:issue][:code]]
          r.client_error error_code
          error_code
        end
      end

      r.server_error do
        r.body[:fault][:faultstring] if r.body.key?(:fault) && r.body[:fault].key?(:faultstring)
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
  def self.authenticate_and_do(logger = nil, _force = false, &block)
    integration ||= fetch

    # TODO: Now, consume the entire process
    # we can optimize this by reusing saved wsdl but we always need to fallback to directory because we can rely on auth and business wsdls
    get_urls.execute(logger) do |c|
      c.success do |response|
        integration ||= fetch

        integration.parameters['authentication_wsdl'] = response[:particular_response][:authentication_wsdl]
        integration.parameters['business_wsdl'] = response[:particular_response][:business_wsdl]

        authenticate(wsdl: integration.parameters['authentication_wsdl']).execute(logger) do |auth_c|
          auth_c.success do |auth_response|
            integration ||= fetch

            integration.parameters['token'] = auth_response[:token]
            integration.save!

            yield block if block_given?
          end

          auth_c.error do |response|
            raise ServiceError, response
          end
        end
      end

      c.error do |response|
        raise ServiceError, response
      end
    end
  end

  def authenticate(parameters = {})
    integration = fetch

    options = ::EdnotifIntegration.default_options.deep_merge(
      globals: {
        namespace_identifier: 'tk',
        namespaces: {
          'xmlns:typ': 'http://www.fiea.org/types/'
        },
        wsdl: parameters['wsdl']
      }
    )

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

        if doc[:standard_response][:result]
          doc
        else
          error_code = YamlNomen[:incoming][:error_codes][doc[:standard_response][:issue][:code]]
          r.client_error error_code
          error_code
        end
      end

      r.server_error do
        r.body[:fault][:faultstring] if r.body.key?(:fault) && r.body[:fault].key?(:faultstring)
      end
    end
  end

  def get_urls(integration = nil)
    # retrieve integration unless it is already supplied (on check_connection step)
    integration ||= fetch

    options = ::EdnotifIntegration.default_options.deep_merge(
      globals: {
        namespace_identifier: 'tk',
        namespaces: {
          'xmlns:typ': 'http://www.fiea.org/types/'
        },
        wsdl: %w[dummy test demo demo-elevage].include?(Ekylibre::Tenant.current) ? ::Ednotif::TEST_DIRECTORY_WSDL : ::Ednotif::DIRECTORY_WSDL
      }
    )

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
        if doc[:standard_response][:result]
          if doc.key?(:particular_response) && doc[:particular_response][:business_wsdl] && doc[:particular_response][:authentication_wsdl]
            doc
          else
            r.error :missing_wsdl
            :missing_wsdl
          end
        else
          error_code = YamlNomen[:incoming][:error_codes][doc[:standard_response][:issue][:code]]
          r.client_error error_code
          error_code
        end
      end

      r.server_error do
        r.body[:fault][:faultstring] if r.body.key?(:fault) && r.body[:fault].key?(:faultstring)
      end
    end
  end
end
