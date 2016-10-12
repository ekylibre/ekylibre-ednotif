module Ednotif
  class EdnotifCreateCattleEntranceJob < ActiveJob::Base
    queue_as :default

    def perform(*args)
      operation_name = :create_cattle_entrance.freeze
      logger = EdnotifLogger.create!(operation_name: operation_name)

      dataset = args.extract_options!

      # TODO: re-enable after testing
      # dataset[:farm_number] = Identifier.where(nature: :cattling_number).first[:value]
      dataset[:farm_number] = 'FR01999999'



      Ednotif::EdnotifIntegration.authenticate_and_do logger do
        integration ||= Ednotif::EdnotifIntegration.fetch

        options = {
            globals: {
                wsdl: integration.parameters['business_wsdl']
            }
        }

        # remember to observe xsd sequences.
        message = {
            token: integration.parameters['token'],
            farm: {
                farm_number: dataset[:farm_number]
            },
            animal:
            {
               identification_number: dataset[:identification_number]
            },
            entry_date: dataset[:entry_date],
            entry_reason: dataset[:entry_reason],
            origin_farm: {
                farm: {
                    farm_number: dataset[:origin_farm_number]
                },
                origin_owner_name: dataset[:origin_owner_name]
            },
            prod_code: dataset[:prod_code],
            cattle_categ_code: dataset[:cattle_categ_code]
        }

        call = Ednotif::EdnotifIntegration.create_cattle_entrance(options: options, message: message)

        binding.pry

        call.execute(logger) do |op_c|
          op_c.success do |op_response|
            binding.pry
            #TODO
          end
          # else
          # handling errors
          #   errors = []
          #   binding.pry
          #
          #   call.each do |k, v|
          #     errors << [k.tl, v]
          #   end
          #   logger.state = errors.to_s
          #   logger.save!
          # end

        end
      end
    end
  end
end