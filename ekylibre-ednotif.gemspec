# frozen_string_literal: true

require_relative 'lib/ekylibre/ednotif/version'

Gem::Specification.new do |spec|
  spec.name = 'ekylibre-ednotif'
  spec.version = Ekylibre::Ednotif::VERSION
  spec.authors = ['Ekylibre developers']
  spec.email = ['dev@ekylibre.com']

  spec.homepage = 'https://www.ekylibre.com'
  spec.required_ruby_version = '>= 2.6.0'
  spec.summary = 'EdNotif integration'
  spec.license = 'AGPL-3.0-only'

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the 'allowed_push_host'
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  if spec.respond_to?(:metadata)
    spec.metadata["allowed_push_host"] = "https://gems.ekylibre.dev"

    spec.metadata["homepage_uri"] = spec.homepage
    spec.metadata["source_code_uri"] = "https://www.gitlab.com/ekylibre/ekylibre-ednotif"
  else
    raise StandardError.new("RubyGems 2.0 or newer is required to protect against public gem pushes.")
  end

  spec.files = Dir.glob(%w[app/**/* config/**/* lib/**/* bin/**/* *.gemspec Gemfile Rakefile *.rdoc])

  spec.add_dependency 'ekylibre_plugin_system', '~> 0.3.0'

  spec.add_development_dependency "bundler", ">= 1.17"
  spec.add_development_dependency "minitest", "~> 5.14"
  spec.add_development_dependency "rake", "~> 13.0"
end
