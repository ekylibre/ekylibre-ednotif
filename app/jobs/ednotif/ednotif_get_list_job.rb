module Ednotif
  class EdnotifGetListJob < ActiveJob::Bse
    queue_as :default

    def perform(*args)
      Ednotif::EdnotifIntegration.get_list(*args).execute do |c|
        #TODO
        # get ekylibre transcoded herd list.
      end

      # c.on :animal_is_already_registered do
      #   #some stuff
      # end
    end
  end
end