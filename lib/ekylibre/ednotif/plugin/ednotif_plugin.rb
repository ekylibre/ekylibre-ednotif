# frozen_string_literal: true

using Corindon::DependencyInjection::Injectable
using Ekylibre::PluginSystem::Sugar::Scripts

module Ekylibre
  module Ednotif
    module Plugin
      class EdnotifPlugin < Ekylibre::PluginSystem::Plugin
        SCRIPT_ADDONS = %w[synchronization_operations].freeze

        injectable do
          args engine: param(Ednotif::Engine)
          tag 'ekylibre.system.plugin'
        end

        # @param [Ekylibre::PluginSystem::Container] container
        def boot(container)
          register_script_addons(SCRIPT_ADDONS, container: container)
        end

        def version
          Ednotif::VERSION
        end
      end
    end
  end
end
