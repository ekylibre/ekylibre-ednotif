module Ednotif
  # class EdnotifIntegration < ActionIntegration::Base
  class EdnotifIntegration
    # auth :check do
    #   parameter :api_key
    # end

    # calls :get_list

    # def check
    # end

    ##
    # get_list: fournir l’inventaire des bovins d’une exploitation entre deux dates. L’inventaire peut être complété par la liste des boucles disponibles.
    # @param [string] token: token from reswel, length: 50
    # @param [string] farm_country_code: Toujours 'FR'. length: 2
    # @param [string] farm_number: Numéro d'exploitation française. length: 8
    # @param [date] start_date: Date début de période de présence des bovins
    # @param [date] end_date: Date fin de période de présence des bovins
    # @param [Object] stock: Indique si le stock de boucles doit être retourné
    def get_list(*args)
      # get hash with ekylibre data
      options = args.shift || {}
      dataset = args.extract_options!

      # integration = fetch

      #transcoding

      fail 'Missing WSDL' unless options.key?(:wsdl)

      # typeExploitationFrancaisePK
      fail 'invalid cattling number' unless dataset[:farm_number] =~ /[0-9]{8}/


      message = {
          'sch:JetonAuthentification': '924ffe40-547f-458e-a06e-f5c9145ed795',
          'sch:Exploitation': {
              'sch:CodePays': 'FR',
              'sch:NumeroExploitation': dataset[:farm_number]
          },
          'sch:DateDebut': dataset[:start_date],
          'sch:StockBoucles': dataset[:get_stock] ? 1 : 0
      }

      options.merge!({
          namespace_identifier: 'sch',
          namespaces: {
              'xmlns:sch': 'http://www.idele.fr/XML/Schema/'
          },
          strip_namespaces: true,
          convert_tags_to: lambda { |tag| tag.snakecase.to_sym },
          advanced_typecasting: true
      })

      #soap call
      call_savon(:ip_b_get_inventaire, options, message) do |r|
        r.success do

          nested = r.body[r.body.keys.first]

          # reject namespaces definition
          nested.reject! { |k, _| k =~ /\A@.*\z/ }

          doc = Ekylibre::Ednotif::InTranscoder.convert(nested)

          if doc[:standard_response][:result]
            parser = Nori.new strip_namespaces: true, convert_tags_to: lambda { |tag| tag.snakecase.to_sym }, advanced_typecasting: true
            # because \n special chars are escaped by default, but it must be considered during base64 decoding.
            embedded_xml = Ekylibre::Ednotif.base64_zip_to_xml doc[:particular_response][:embedded_document].gsub(/\\n/,"\n")
            hashed = parser.parse(embedded_xml.to_xml)

            # :message_ip_b_notif_get_inventaire + reject @namespaces definitions
            nested = hashed[hashed.keys.first].reject{ |k, _| k =~ /\A@.*\z/ }

            doc = Ekylibre::Ednotif::InTranscoder.convert(nested)
          else
            r.error YamlNomen[:incoming][:error_codes][doc[:standard_response][:code]]
          end

          # hash format
          doc

        end
      end
    end
  end
end
