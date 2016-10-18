module Ednotif
  class EdnotifCreateCattleExitJob < ActiveJob::Base
    queue_as :default

    def perform(*args)
      operation_name = :create_cattle_exit.freeze
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
            exit_date: dataset[:exit_date],
            exit_reason: dataset[:exit_reason],
            destination_farm: {
                farm: {
                    farm_number: dataset[:dest_farm_number]
                },
                owner_name: dataset[:dest_owner_name]
            }
        }

        p = proc do |_, v|
          v.delete_if(&p) if v.respond_to? :delete_if
          v.nil? || v.respond_to?(:'empty?') && v.empty?
        end
        message.delete_if(&p)


        call = Ednotif::EdnotifIntegration.create_cattle_exit(options: options, message: message)

        call.execute(logger) do |op_c|
          op_c.success do |op_response|
            binding.pry
            op_response
            #TODO
          end
          # if transcoding error occurs on OutTranscoder
          op_c.error :transcoding_error do |op_response|
            errors = []

            op_response.each do |k, v|
              errors << [k.tl, v]
            end

            logger.state = errors.to_s
            logger.save!
          end

          op_c.error do |op_response|
            logger.state = op_response
            logger.save!
          end

        end
      end
    end
  end
end