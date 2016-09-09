# autoload won't work on conditional module inclusion
require 'ekylibre/ednotif'

autoload :Ednotif, 'ednotif'

# Ednotif::EdnotifIntegration.on_check_success do
  # Ednotif::EdnotifGetListJob.perform_later
# end

#hook : subscribe :new_birth,


# Loads transcoding tables
files = Dir.glob(Ekylibre::Ednotif.in_transcoding_dir.join('*')) - Dir.glob(Ekylibre::Ednotif.in_transcoding_dir.join('*.exception.yml'))
YamlNomen.load(:incoming, files)

files = Dir.glob(Ekylibre::Ednotif.out_transcoding_dir.join('*')) - Dir.glob(Ekylibre::Ednotif.out_transcoding_dir.join('*.exception.yml'))
YamlNomen.load(:outgoing, files)