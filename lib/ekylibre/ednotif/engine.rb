module Ekylibre
  module Ednotif
    class Engine < ::Rails::Engine
      initializer :assets do |app|
        app.config.assets.precompile += %w[integrations/ednotif]
      end

      initializer :i18n do |app|
        app.config.i18n.load_path += Dir[Ekylibre::Ednotif::Engine.root.join('config', 'locales', '**', '*.yml')]
      end

      initializer :extend_navigation do |_app|
        Ekylibre::Navigation.exec_dsl do
          part :production do
            group :animal_management do
              item :synchronization_operation do
                page 'backend/synchronization_operations#index'
                page 'backend/synchronization_operations#show'
              end
            end
          end
        end
      end

      initializer :extend_toolbar do |_app|
        Ekylibre::View::Addon.add('backend/animals/import_cattling_inventory_toolbar', to: :toolbar, for_action: 'backend/animals#index')
      end
    end
  end
end
