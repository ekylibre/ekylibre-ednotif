module Ednotif
  class Engine < ::Rails::Engine
    initializer :assets do |app|
      app.config.assets.precompile += %w( integrations/ednotif )
    end

    initializer :i18n do |app|
      app.config.i18n.load_path += Dir[Ednotif::Engine.root.join('config', 'locales', '**', '*.yml')]
    end
  end
end
