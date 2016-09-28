module Ednotif
  class EdnotifGetListJob < ActiveJob::Base
    queue_as :default

    def perform(*args)
      operation_name = :get_list.freeze
      dataset = args.extract_options!

      farm_number = Identifier.where(nature: :cattling_number)

      dataset[:farm_number] = farm_number.first[:value][2..10] unless farm_number.empty?
      dataset[:start_date] ||= Date.today.to_s
      dataset[:get_stock] ||= false


      ### validations

      #tmp
      fail 'farm number empty' unless farm_number.present?
      fail 'invalid start date' unless Date.parse(dataset[:start_date]) <= Date.today
      fail 'end date must be superior to start date' unless dataset[:end_date].blank? or Date.parse(dataset[:start_date]) <= Date.parse(dataset[:end_date])
      fail 'invalid get stock value' unless [true, false].include? dataset[:get_stock]

      message = {
          token: dataset[:token],
          farm: {
              country_code: dataset[:country_code],
              farm_number: dataset[:farm_number]
          },
          start_date: dataset[:start_date],
          stock: dataset[:get_stock]
      }

      message.merge!(end_date: dataset[:end_date]) if dataset.key? :end_date

      logger = EdnotifLogger.create!(operation_name: operation_name)

      Ednotif::EdnotifIntegration.authenticate_and_do logger do
        # TODO message
        # Ednotif::EdnotifIntegration.get_list(options: options, message: message).execute do |c|
        #   c.success do |response|
        #   end
        # end
      end
    end
  end
end