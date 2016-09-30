module Ekylibre
  module Ednotif
    class OutTranscoder

      class << self

        # complexTypes:
        def method_missing(m, h, &block)
          h.each_with_object({}) do |(k, v), h|
            h.merge! send k, v
          end
        end

        def enquirer_profile(fragment)
          {
              'tk:ProfilDemandeur': convert(fragment)
          }
        end

        def filiation(fragment)
          {
              'edn:Filiation': convert(fragment)
          }
        end

        def profile(fragment)
          {
              'typ:Profil': convert(fragment)
          }
        end

        def version(fragment)
          {
              'tk:VersionPK': convert(fragment)
          }
        end

        def farm(fragment)
          {
              'edn:Exploitation': convert(fragment)
          }
        end

        def birth_farm(fragment)
          {
              'edn:ExploitationNaissance': convert(fragment)
          }
        end

        def animal(fragment)
          {
              'edn:Bovin': convert(fragment)
          }
        end

        def weight(fragment)
          {
              'edn:Poids': convert(fragment)
          }
        end

        def mother(fragment)
          {
              'edn:MerePorteuse': convert(fragment)
          }
        end

        def father(fragment)
          {
              'edn:PereIPG': convert(fragment)
          }
        end

        #terminals:

        def passport_request(fragment)
          {
              'edn:DemandePasseport': fragment
          }
        end

        def work_code(fragment)
          {
              'edn:CodeAtelier': YamlNomen[:outgoing][:work_code][fragment]
          }
        end

        def birth_weight(fragment)
          {
              'edn:PoidsNaissance': fragment
          }
        end

        def weighed_weight(fragment)
          {
              'edn:PoidsPese': fragment
          }
        end

        def chest_size(fragment)
          {
              'edn:TourPoitrine': fragment
          }
        end

        def transplantation(fragment)
          {
              'edn:TransplantationEmbryonnaire': fragment
          }
        end

        def abortion(fragment)
          {
              'edn:Avortement': fragment
          }
        end

        def birth_condition(fragment)
          {
              'edn:ConditionNaissance': YamlNomen[:outgoing][:mammalia_birth_conditions][fragment]
          }
        end

        def twin(fragment)
          {
              'edn:Jumeau': fragment
          }
        end

        def token(fragment)
          {
              'edn:JetonAuthentification': fragment
          }
        end

        def login(fragment)
          {
              'typ:UserId': fragment
          }
        end

        def password(fragment)
          {
              'typ:Password': fragment
          }
        end

        def enterprise(fragment)
          {
              'typ:Entreprise': fragment
          }
        end

        def application(fragment)
          {
              'typ:Application': fragment
          }
        end

        def version_number(fragment)
          {
              'typ:NumeroVersion': fragment
          }
        end

        def site_code_version(fragment)
          {
              'typ:CodeSiteVersion': fragment
          }
        end

        def service_name(fragment)
          {
              'typ:NomService': fragment
          }
        end

        def site_code_service(fragment)
          {
              'typ:CodeSiteService': fragment
          }
        end

        def country_code(fragment)
          {
              'edn:CodePays': YamlNomen[:outgoing][:countries][fragment]
          }
        end

        def identification_number(fragment)
          {
              'edn:NumeroNational': fragment
          }
        end

        def sex(fragment)
          {
              'edn:Sexe': YamlNomen[:outgoing][:sexes][fragment]
          }
        end

        def race_code(fragment)
          {
              'edn:TypeRacial': YamlNomen[:outgoing]['varieties-bos_taurus'][fragment]
          }
        end

        def birth_date(fragment)
          # as a DateTime object
          {
              'edn:DateNaissance': fragment.to_s
          }
        end

        def work_number(fragment)
          {
              'edn:NumeroTravail': fragment
          }
        end

        def name(fragment)
          {
              'edn:NomBovin': fragment
          }
        end

        def farm_number(fragment)
          {
              'edn:NumeroExploitation': fragment[2..10]
          }.reverse_merge(country_code(fragment[0..1].downcase))
        end

        def start_date(fragment)
          {
              'edn:DateDebut': fragment.to_s
          }
        end

        def end_date(fragment)
          {
              'edn:DateFin': fragment.to_s
          }
        end

        def stock(fragment)
          {
              'edn:StockBoucles': true & fragment ? 1 : 0
          }
        end

        def convert(message)
          message.each_with_object({}) do |(k, v), h|
            h.merge!(send(k, v).reject{ |_,v| v.blank? })
          end
        end

      end
    end
  end
end
