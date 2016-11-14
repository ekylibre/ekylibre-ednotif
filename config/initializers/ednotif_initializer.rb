autoload :Ednotif, 'ednotif'

# Ednotif::EdnotifIntegration.on_check_success do
  # Ednotif::EdnotifGetListJob.perform_later
# end

Ekylibre::Hook.subscribe :get_inventory do |data|
  Ednotif::GetInventoryJob.perform_later(data)
end

# Loads transcoding tables
files = Dir.glob(Ekylibre::Ednotif.in_transcoding_dir.join('*')) - Dir.glob(Ekylibre::Ednotif.in_transcoding_dir.join('*.exception.yml'))
YamlNomen.load(:incoming, files)

files = Dir.glob(Ekylibre::Ednotif.out_transcoding_dir.join('*')) - Dir.glob(Ekylibre::Ednotif.out_transcoding_dir.join('*.exception.yml'))
YamlNomen.load(:outgoing, files)