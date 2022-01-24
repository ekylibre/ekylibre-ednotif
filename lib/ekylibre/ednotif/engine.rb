# frozen_string_literal: true

module Ekylibre
  module Ednotif
    class Engine < ::Rails::Engine
      initializer 'ekylibre_ednotif.assets.precompile' do |app|
        app.config.assets.precompile += %w[synchronization_operations.coffee integrations/ednotif.png]
      end

      initializer :i18n do |app|
        app.config.i18n.load_path += Dir[Ekylibre::Ednotif::Engine.root.join('config', 'locales', '**', '*.yml')]
      end

      initializer :extend_toolbar do |_app|
        Ekylibre::View::Addon.add(:main_toolbar, 'backend/animals/import_cattling_inventory_toolbar', to: 'backend/animals#index')
      end

      initializer :extend_cobble do |_app|
        Ekylibre::View::Addon.add(:cobbler, 'backend/animals/inventory_cobble', to: 'backend/animals#show')
      end

      initializer :ekylibre_ednotif_import_javascript do
        tmp_file = Rails.root.join('tmp', 'plugins', 'javascript-addons', 'plugins.js.coffee')
        tmp_file.open('a') do |f|
          import = '#= require synchronization_operations'
          f.puts(import) unless tmp_file.open('r').read.include?(import)
        end
      end

    end
  end
end
