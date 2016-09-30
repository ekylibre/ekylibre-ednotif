module Ekylibre
  module Ednotif
    class InTranscoder

      class << self

        # complexTypes:
        def method_missing(m, h, &block)
          h.each_with_object({}) do |(k, v), h|
            h.merge! send k, v
          end
        end

        def identite_bovin(fragment)
          {
              identity: convert(fragment)
          }
        end

        def bovin(fragment)
          #oh my!

          # a set of many animals
          if fragment.is_a? Array
            {
                animals: fragment.collect do |animal|
                  convert animal
                end
            }
          else
            # same tag name can occurs to identify an uniq animal too...
            convert fragment
          end
        end

        def reponse_standard(fragment)
          {
              standard_response: convert(fragment)
          }
        end

        def reponse_specifique(fragment)
          {
              particular_response: convert(fragment)
          }
        end

        def anomalie(fragment)
          {
              issue: convert(fragment)
          }
        end

        def date_naissance(fragment)
          {
              birth_date: convert(fragment)
          }
        end

        def entree_validee(fragment)
          {
              validated_entry: convert(fragment)
          }
        end

        def exit_validee(fragment)
          {
              validated_exit: convert(fragment)
          }
        end

        def mere_porteuse(fragment)
          {
              mother: convert(fragment)
          }
        end

        def pere_ipg(fragment)
          {
              father: convert(fragment)
          }
        end

        def exploitation(fragment)
          {
              farm: convert(fragment)
          }
        end

        def entree(fragment)
          {
              entry: convert(fragment)
          }
        end

        def mouvement_entree_bovin(fragment)
          {
              entry_mouvement: convert(fragment)
          }
        end

        def mouvement_sortie_bovin(fragment)
          {
              exit_mouvement: convert(fragment)
          }
        end

        def sortie(fragment)
          {
              exit: convert(fragment)
          }
        end

        def periode_presence(fragment)

          # an array on multiple records, an hash otherwise

          fragment = [fragment] if fragment.is_a? Hash

          if fragment.is_a? Array
            {
                mouvements: fragment.collect do |animal|
                  convert animal
                end
            }
          end
        end

        def sortie_presumee(fragment)

          # an array on multiple records, an hash otherwise

          fragment = [fragment] if fragment.is_a? Hash

          if fragment.is_a? Array
            {
                presumed_exit: fragment.collect do |animal|
                  convert animal
                end
            }
          end
        end

        def serie_boucles(fragment)
          # an array on multiple records, an hash otherwise

          fragment = [fragment] if fragment.is_a? Hash

          if fragment.is_a? Array
            {
                buckles_serie: fragment.collect do |serie|
                  convert serie
                end
            }
          end
        end

        def boucles(fragment)
          # an array on multiple records, an hash otherwise

          fragment = [fragment] if fragment.is_a? Hash

          if fragment.is_a? Array
            {
                buckles: fragment.collect do |buckle|
                  convert buckle
                end
            }
          end
        end

        def fin_de_vie(fragment)
          {
              end_of_life: convert(fragment)
          }
        end

        # Terminals
        def date_heure_generation(fragment)
          {
              generation_datetime: fragment
          }
        end

        def date_debut(fragment)
          {
              start_date: fragment
          }
        end

        def date_entree(fragment)
          {
              entry_date: fragment
          }
        end

        def cause_entree(fragment)
          {
              entry_reason: YamlNomen[:incoming][:entry_reason][fragment]
          }
        end

        def date_sortie(fragment)
          {
              exit_date: fragment
          }
        end

        def cause_sortie(fragment)
          {
              exit_reason: YamlNomen[:incoming][:exit_reason][fragment]
          }
        end

        def date(fragment)
          {
              date: fragment
          }
        end

        def date_fin(fragment)
          {
              end_date: fragment
          }
        end

        def date_premier_velage(fragment)
          {
              first_calving_date: fragment
          }
        end

        def temoin_completude(fragment)
          {
              witness: YamlNomen[:incoming][:witness][fragment]
          }
        end


        def numero_travail(fragment)
          {
              work_number: fragment
          }
        end

        def nom_bovin(fragment)
          {
              name: fragment
          }
        end

        def resultat(fragment)
          {
              result: fragment
          }
        end

        def statut_filie(fragment)
          {
              cpb_filiation_status: fragment
          }
        end


        def stock_boucles(fragment)
          {
              stock: fragment
          }
        end

        def code_pays(fragment)
          {
              country_code: YamlNomen[:incoming][:countries][fragment]
          }
        end

        def code_pays_origine(fragment)
          {
              origin_country_code: YamlNomen[:incoming][:countries][fragment]
          }
        end

        def numero_national(fragment)
          {
              identification_number: fragment
          }
        end

        def numero_origine(fragment)
          {
              origin_identification_number: fragment
          }
        end

        def sexe(fragment)
          {
              sex: YamlNomen[:incoming][:sexes][fragment]
          }
        end

        def type_racial(fragment)
          {
              race_code: YamlNomen[:incoming]['varieties-bos_taurus'][fragment]
          }
        end

        def numero_exploitation(fragment)
          {
              farm_number: fragment
          }
        end

        def debut_serie(fragment)
          {
              start_date: fragment
          }
        end

        def quantite(fragment)
          {
              quantity: fragment
          }
        end

        def attente_validation_bdni(fragment)
          {
              waiting_validation: fragment
          }
        end

        def date_fin_de_vie(fragment)
          {
              end_of_life_date: fragment
          }
        end

        def temoin_fin_de_vie(fragment)
          {
              end_of_life_witness: YamlNomen[:incoming][:witness][fragment]
          }
        end

        # error code
        def code(fragment)
          {
              code: fragment
          }
        end

        def severite(fragment)
          {
              severity: fragment
          }
        end

        def message(fragment)
          {
              message: fragment
          }
        end

        def nb_bovins(fragment)
          {
              count: fragment
          }
        end

        def message_zip(fragment)
          {
              embedded_document: fragment
          }
        end

        def url_guichet(fragment)
          {
              authentication_url: fragment
          }
        end

        def url_metier(fragment)
          {
              business_url: fragment
          }
        end

        def wsdl_guichet(fragment)
          {
              authentication_wsdl: fragment
          }
        end

        def wsdl_metier(fragment)
          {
              business_wsdl: fragment
          }
        end

        def jeton(fragment)
          {
              token: fragment
          }
        end

        def convert(message)
          message.each_with_object({}) do |(k, v), h|
            h.merge!(send(k, v)||{})
          end
        end

      end
    end
  end
end
