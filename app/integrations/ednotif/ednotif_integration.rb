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
          }
      })

      #soap call
      call_savon(:ip_b_get_inventaire, options, message) do |r|
        r.success do

          # find any business error
          if response.xpath('//tns:ReponseStandard/tnsfiea:Resultat').text == 'false'
            code = response.xpath('//tns:ReponseStandard/tnsfiea:Anomalie/tnsfiea:Code').text

            #TODO improve this
            error_codes = YAML.load_file(Ekylibre::Ednotif.in_transcoding_dir.join('error_codes.yml'))

            return r.error error_codes[code] if code.present? and error_codes.key?(code)

            # fallback to return message
            return r.error response.xpath('//tns:ReponseStandard/tnsfiea:Anomalie/tnsfiea:Message').text
          end

          doc = Ekylibre::Ednotif.base64_zip_to_xml response.xpath('//tns:MessageZip').text

          return r.error 'MessageZip not found' if doc.nil?

          # get message and transcode
          res = {
              generation_datetime: doc.xpath('//tns:DateHeureGeneration').text,
              country_code: doc.xpath('//tns:Exploitation/tns:CodePays').text,
              farm_number: doc.xpath('//tns:Exploitation/tns:NumeroExploitation').text,
              start_date: Date.parse(doc.xpath('//tns:DateDebut').text),
              end_date: Date.parse(doc.xpath('//tns:DateFin').text),
              stock: doc.xpath('//tns:StockBoucles').text,
              herd: []
          }

          res[:herd] = doc.xpath('//tns:Bovin').collect do |node|
            hash = {}
            identity = node.xpath('./tns:IdentiteBovin')
            unless identity.nil?
              hash[:country_code] = identity.xpath('./tns:Bovin/tns:CodePays').text
              hash[:identification_number] = identity.xpath('./tns:Bovin/tns:NumeroNational').text
              hash[:sex] = identity.xpath('./tns:Sexe').text
              hash[:race_code] = identity.xpath('./tns:TypeRacial').text
              hash[:birth_date] = Date.parse(identity.xpath('./tns:DateNaissance/tns:Date').text)
              hash[:witness] = identity.xpath('./tns:DateNaissance/tns:TemoinCompletude').text
              hash[:work_number] = identity.xpath('./tns:NumeroTravail').text
              hash[:name] = identity.xpath('./tns:NomBovin').text
              hash[:cpb_filiation] = identity.xpath('./tns:StatutFilie').text
              hash[:mother] = {
                  country_code: identity.xpath('./tns:MerePorteuse/tns:Bovin/tns:CodePays').text,
                  identification_number: identity.xpath('./tns:MerePorteuse/tns:Bovin/tns:NumeroNational').text,
                  race_code: identity.xpath('./tns:MerePorteuse/tns:TypeRacial').text
              }
              hash[:father] = {
                  country_code: identity.xpath('./tns:PereIPG/tns:Bovin/tns:CodePays').text,
                  identification_number: identity.xpath('./tns:PereIPG/tns:Bovin/tns:NumeroNational').text,
                  race_code: identity.xpath('./tns:PereIPG/tns:TypeRacial').text
              }
              hash[:parturition_first_date] = identity.xpath('./tns:DatePremierVelage').text
              hash[:birth_farm] = {
                  country_code: identity.xpath('./tns:ExploitationNaissance/tns:CodePays').text,
                  farm_number: identity.xpath('./tns:ExploitationNaissance/tns:NumeroExploitation').text
              }
              hash[:source_country_code] =  identity.xpath('./tns:CodePaysOrigine').text
              hash[:source_indentification_number] =  identity.xpath('./tns:NumeroOrigine').text
              hash[:end_of_life] =  {
                  end_of_life_date: identity.xpath('./tns:DateFinDeVie').text,
                  end_of_life_witness: identity.xpath('./tns:TemoinFinDeVie').text
              }
            end

            ###TO BE CONTINUED###
          end

          # result =
          # response.xpath('//tns:MessageZip').text

        end
      end
    end
  end
end
