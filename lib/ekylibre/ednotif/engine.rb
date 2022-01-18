# frozen_string_literal: true

module Ekylibre
  module Ednotif
    class Engine < ::Rails::Engine
      initializer 'ekylibre_ednotif.assets.precompile' do |app|
        app.config.assets.precompile += %w[integrations/ednotif.png]
      end

      initializer :i18n do |app|
        app.config.i18n.load_path += Dir[Ekylibre::Ednotif::Engine.root.join('config', 'locales', '**', '*.yml')]
      end

      initializer :extend_toolbar do |_app|
        Ekylibre::View::Addon.add('backend/animals/import_cattling_inventory_toolbar', to: :toolbar, for_action: 'backend/animals#index')
      end

      initializer :extend_cobble do |_app|
        Ekylibre::View::Addon.add(:cobbler, 'backend/animals/inventory_cobble', to: 'backend/animals#show')
      end
    end
  end
end
