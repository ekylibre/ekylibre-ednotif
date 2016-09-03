module Ekylibre
  module Ednotif
    EDNOTIF_VERSION = 1
    #in/ : from Ednotif to Ekylibre transcoding
    #out/ : from Ekylibre to Ednotif transcoding

    class << self
      def root
        Ekylibre.root.join('plugins', 'ednotif', 'lib', 'ekylibre', 'ednotif')
      end

      def transcoding_dir
        root.join('transcoding')
      end

      def in_transcoding_dir
        transcoding_dir.join('in')
      end

      def out_transcoding_dir
        transcoding_dir.join('out')
      end

      def import_dir
        root.join('resources')
      end

      def schema_definition
        import_dir.join('IpBNotif_v1.xsd') if EDNOTIF_VERSION == 1
      end

      def schema_url
        'http://idele.fr/XML/Schema/'.freeze
      end

      def transcoding_manifest
        Ekylibre::Tenant.private_directory.join('plugins', 'ednotif', 'manifest.log')
      end

      def transcoding_routines
        transcoding_dir.join('routines.yml')
      end
    end

    ACTIONS = {
        parturition: :create_new_birth,
        animal_artificial_insemination: :create_insemination
    }

    def self.included(base)
      # base.send :helper_method, :ednotify? if base.respond_to? :helper_method

      base.instance_eval do
        after_create :notify
      end

      base.class_eval do

        def ednotify?
          true
        end

        def notify

          if self.is_a? Intervention and nature == 'record'
            actions.each do |action|
              next unless  ACTIONS.key? action
              ::Ekylibre::Ednotif::ServiceCaller.send ACTIONS[:action], self
            end
          elsif self.is_a? Purchase

          end
          true
        end
      end
    end
  end
end