$:.push File.expand_path("../lib", __FILE__)

require "ednotif/version"

Gem::Specification.new do |s|
  s.name        = 'ednotif'
  s.version     = Ednotif::VERSION
  s.authors     = ["Nicolas Procureur", "Brice Texier", "Alexandre Lécuelle"]
  s.email       = ["nprocureur@ekylibre.com", "brice@ekylibre.com", "alecuelle@ekylibre.com"]
  s.homepage    = "https://forge.ekylibre.com/projects/animals"
  s.summary     = "Gestion ergonomique et simple des animaux dans Ekylibre"
  s.description = "Gestion ergonomique et simple des animaux dans Ekylibre"
  s.license     = "MIT"

  s.files = Dir["{app,config,lib}/**/*", "Rakefile", "README.rdoc"]
end
