# coding: utf-8

$LOAD_PATH.push File.expand_path('../lib', __FILE__)

require 'ekylibre/ednotif/version'

Gem::Specification.new do |s|
  s.name        = 'ekylibre-ednotif'
  s.version     = Ekylibre::Ednotif::VERSION
  s.authors     = ['Nicolas Procureur', 'Brice Texier', 'Alexandre Lécuelle']
  s.email       = ['nprocureur@ekylibre.com', 'brice@ekylibre.com', 'alecuelle@ekylibre.com']
  s.homepage    = 'https://github.com/ekylibre/ekylibre-ednotif'
  s.summary     = 'EdNotif integration'
  s.license     = 'MIT'

  s.files = Dir['{app,config,lib}/**/*', 'Rakefile', 'README.rdoc']
end
