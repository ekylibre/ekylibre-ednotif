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
              'sch:Filiation': convert(fragment)
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
              'sch:Exploitation': convert(fragment)
          }
        end

        def birth_farm(fragment)
          {
              'sch:ExploitationNaissance': convert(fragment)
          }
        end

        def animal(fragment)
          {
              'sch:Bovin': convert(fragment)
          }
        end

        def weight(fragment)
          {
              'sch:Poids': convert(fragment)
          }
        end

        def mother(fragment)
          {
              'sch:MerePorteuse': convert(fragment)
          }
        end

        def father(fragment)
          {
              'sch:PereIPG': convert(fragment)
          }
        end

        #terminals:

        def passport_request(fragment)
          {
              'sch:DemandePasseport': fragment
          }
        end

        def work_code(fragment)
          {
              'sch:CodeAtelier': YamlNomen[:outgoing][:work_code][fragment]
          }
        end

        def birth_weight(fragment)
          {
              'sch:PoidsNaissance': fragment
          }
        end

        def weighed_weight(fragment)
          {
              'sch:PoidsPese': fragment
          }
        end

        def chest_size(fragment)
          {
              'sch:TourPoitrine': fragment
          }
        end

        def transplantation(fragment)
          {
              'sch:TransplantationEmbryonnaire': fragment
          }
        end

        def abortion(fragment)
          {
              'sch:Avortement': fragment
          }
        end

        def birth_condition(fragment)
          {
              'sch:ConditionNaissance': YamlNomen[:outgoing][:mammalia_birth_conditions][fragment]
          }
        end

        def twin(fragment)
          {
              'sch:Jumeau': fragment
          }
        end

        def token(fragment)
          {
              'sch:JetonAuthentification': fragment
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
              'sch:CodePays': YamlNomen[:outgoing][:countries][fragment]
          }
        end

        def identification_number(fragment)
          {
              'sch:NumeroNational': fragment
          }
        end

        def sex(fragment)
          {
              'sch:Sexe': YamlNomen[:outgoing][:sexes][fragment]
          }
        end

        def race_code(fragment)
          {
              'sch:TypeRacial': YamlNomen[:outgoing]['varieties-bos_taurus'][fragment]
          }
        end

        def birth_date(fragment)
          # as a DateTime object
          {
              'sch:DateNaissance': fragment.to_s
          }
        end

        def work_number(fragment)
          {
              'sch:NumeroTravail': fragment
          }
        end

        def name(fragment)
          {
              'sch:NomBovin': fragment
          }
        end

        def farm_number(fragment)
          {
              'sch:NumeroExploitation': fragment
          }
        end

        def start_date(fragment)
          {
              'sch:DateDebut': fragment.to_s
          }
        end

        def stock(fragment)
          {
              'sch:StockBoucles': fragment
          }
        end

        def convert(message)
          message.each_with_object({}) do |(k, v), h|
            h.merge! send k, v
          end
        end

      end
    end
  end
end
