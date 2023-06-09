require 'yaml_nomen'

module Ekylibre
  module Ednotif
    class OutTranscoder
      class << self
        # complexTypes:
        def method_missing(_m, h)
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

        def origin_farm(fragment)
          {
            'edn:ExploitationProvenance': convert(fragment)
          }
        end

        def destination_farm(fragment)
          {
            'edn:ExploitationDestination': convert(fragment)
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

        # terminals:

        def passport_ask(fragment)
          {
            'edn:DemandePasseport': true & fragment ? 1 : 0
          }
        end

        def prod_code(fragment)
          return :invalid_prod_code if fragment.blank?

          {
            'edn:CodeAtelier': fragment
          }
        end

        def cattle_categ_code(fragment)
          return :invalid_cattle_categ_code if fragment.blank?

          {
            'edn:CodeCategorieBovin': fragment
          }
        end

        def birth_weight(fragment)
          return :invalid_birth_weight unless fragment.to_s.to_i <= 99

          {
            'edn:PoidsNaissance': fragment
          }
        end

        def weighed_weight(fragment)
          {
            'edn:PoidsPese': true & fragment ? 1 : 0
          }
        end

        def chest_size(fragment)
          return :invalid_chest_size unless fragment.to_s.to_i <= 999

          {
            'edn:TourPoitrine': fragment
          }
        end

        def transplant(fragment)
          {
            'edn:TransplantationEmbryonnaire': true & fragment ? 1 : 0
          }
        end

        def abortion(fragment)
          {
            'edn:Avortement': true & fragment ? 1 : 0
          }
        end

        def birth_condition(fragment)
          return :invalid_birth_condition if YamlNomen[:outgoing][:mammalia_birth_conditions][fragment].nil?

          {
            'edn:ConditionNaissance': YamlNomen[:outgoing][:mammalia_birth_conditions][fragment]
          }
        end

        def twin(fragment)
          {
            'edn:Jumeau': true & fragment ? 1 : 0
          }
        end

        def token(fragment)
          return :invalid_token if fragment.blank?

          {
            'edn:JetonAuthentification': fragment
          }
        end

        def login(fragment)
          return :invalid_login if fragment.blank?

          {
            'typ:UserId': fragment
          }
        end

        def password(fragment)
          return :invalid_password if fragment.blank?

          {
            'typ:Password': fragment
          }
        end

        def enterprise(fragment)
          return :invalid_enterprise if fragment.blank?

          {
            'typ:Entreprise': fragment
          }
        end

        def application(fragment)
          return :invalid_application_name if fragment.blank?

          {
            'typ:Application': fragment
          }
        end

        def version_number(fragment)
          return :invalid_version_number if fragment.blank?

          {
            'typ:NumeroVersion': fragment
          }
        end

        def site_code_version(fragment)
          return :invalid_site_code_version if fragment.blank?

          {
            'typ:CodeSiteVersion': fragment
          }
        end

        def service_name(fragment)
          return :invalid_service_name if fragment.blank?

          {
            'typ:NomService': fragment
          }
        end

        def site_code_service(fragment)
          return :invalid_site_code_service if fragment.blank?

          {
            'typ:CodeSiteService': fragment
          }
        end

        def country_code(fragment)
          return :invalid_country_code unless fragment =~ /[a-z]{2}/

          {
            'edn:CodePays': YamlNomen[:outgoing][:countries][fragment]
          }
        end

        def identification_number(fragment)
          # return :invalid_identification_number unless fragment =~ /[A-Za-z0-9]{10,12}/
          if fragment =~ /[A-Za-z]{2}[0-9]{10}/
            {
              'edn:NumeroNational': fragment[2..11]
            }.reverse_merge(country_code(fragment[0..1].downcase))
          elsif fragment =~ /[0-9]{10}/
            {
              'edn:NumeroNational': fragment
            }
          else
            :invalid_identification_number
          end
        end

        def sex(fragment)
          return :invalid_sex if YamlNomen[:outgoing][:sexes][fragment].nil?

          {
            'edn:Sexe': YamlNomen[:outgoing][:sexes][fragment]
          }
        end

        def race_code(fragment)
          return :invalid_race_code if YamlNomen[:outgoing]['varieties-bos_taurus'][fragment].nil?

          {
            'edn:TypeRacial': YamlNomen[:outgoing]['varieties-bos_taurus'][fragment]
          }
        end

        def birth_date(fragment)
          {
            'edn:DateNaissance': Date.parse(fragment)
          }
        rescue
          # as a DateTime object
          return :invalid_birth_date
        end

        def work_number(fragment)
          return :invalid_work_number if fragment.blank?

          {
            'edn:NumeroTravail': fragment
          }
        end

        def name(fragment)
          return :invalid_name if fragment.blank?

          {
            'edn:NomBovin': fragment
          }
        end

        def farm_number(fragment)
          return :invalid_farm_number unless fragment =~ /[A-Za-z]{2}[0-9]{8}/

          {
            'edn:NumeroExploitation': fragment[2..10]
          }.reverse_merge(country_code(fragment[0..1].downcase))
        end

        def origin_owner_name(fragment)
          return :invalid_origin_owner_name if fragment.blank?

          {
            'edn:NomExploitation': fragment
          }
        end

        def owner_name(fragment)
          return :invalid_owner_name if fragment.blank?

          {
            'edn:NomExploitation': fragment
          }
        end

        def start_date(fragment)
          {
            'edn:DateDebut': Date.parse(fragment)
          }
        rescue
          return :invalid_start_date
        end

        def end_date(fragment)
          {
            'edn:DateFin': Date.parse(fragment)
          }
        rescue
          return :invalid_end_date
        end

        def stock(fragment)
          {
            'edn:StockBoucles': true & fragment ? 1 : 0
          }
        end

        def entry_date(fragment)
          {
            'edn:DateEntree': Date.parse(fragment)
          }
        rescue
          return :invalid_entry_date
        end

        def entry_reason(fragment)
          return :invalid_entry_reason if YamlNomen[:outgoing][:entry_reason][fragment].nil?

          {
            'edn:CauseEntree': YamlNomen[:outgoing][:entry_reason][fragment]
          }
        end

        def exit_date(fragment)
          {
            'edn:DateSortie': Date.parse(fragment)
          }
        rescue
          return :invalid_exit_date
        end

        def exit_reason(fragment)
          return :invalid_exit_reason if YamlNomen[:outgoing][:exit_reason][fragment].nil?

          {
            'edn:CauseSortie': YamlNomen[:outgoing][:exit_reason][fragment]
          }
        end
      end

      attr_reader :errors
      attr_reader :message

      def initialize(message)
        @errors = {}
        @message = convert message
      end

      def valid?
        @errors.blank?
      end

      def convert(hash)
        hash.each_with_object({}) do |(k, v), h|
          message = self.class.send(k, v)
          if message.is_a? Hash
            message.reject { |_, v| v.blank? }
            h.merge!(message)
          else
            @errors[message] = v.to_s
          end
        end
      end
    end
  end
end
