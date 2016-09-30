module Ednotif
  class EdnotifGetListJob < ActiveJob::Base
    queue_as :default

    def perform(*args)
      operation_name = :get_list.freeze
      logger = EdnotifLogger.create!(operation_name: operation_name)

      dataset = args.extract_options!

      # TODO: re-enable after testing
      # dataset[:farm_number] = Identifier.where(nature: :cattling_number).first[:value]
      dataset[:farm_number] = 'FR01999999'

      dataset[:start_date] ||= Date.today
      dataset[:get_stock] ||= false


      ### validations

      #tmp
      fail 'farm number is empty' unless dataset[:farm_number].present? and dataset[:farm_number] =~ /[A-Za-z]{2}[0-9]{8}/
      fail 'invalid start date' unless dataset[:start_date] <= Date.today
      fail 'end date must be superior to start date' unless dataset[:end_date].blank? or dataset[:start_date] <= dataset[:end_date]
      fail 'invalid get stock value' unless [true, false].include? dataset[:get_stock]


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
            start_date: dataset[:start_date],
            end_date: dataset.key?(:end_date) ? dataset[:end_date] : nil,
            stock: dataset[:get_stock]
        }

        Ednotif::EdnotifIntegration.get_list(options: options, message: message).execute(logger) do |op_c|
          op_c.success do |op_response|
            op_response
            binding.pry
            # work with ekylibre hash
          end
        end
      end
    end
  end
end