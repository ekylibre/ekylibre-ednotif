module Ekylibre
  module Ednotif
    class Dispatcher
      class << self

        def get_list(*args)
          # record = args.shift
          dataset = args.extract_options!

          dataset[:farm_number] = Identifier.where(nature: :cattling_number).(2..10)
          dataset[:start_date] ||= Date.today.to_s
          dataset[:get_stock] ||= false


          ### validations

          #tmp
          fail 'invalid start date' unless Date.parse(dataset[:start_date]) <= Date.today.to_s
          fail 'end date must be superior to start date' unless dataset[:end_date].blank? or Date.parse(dataset[:start_date]) <= Date.parse(dataset[:end_date])
          fail 'invalid get stock value' unless [true, false].include? dataset[:get_stock]

          #HERE get required parameters and build hash

          # give hash to serviceCaller and let it transcode and soap
          # EdnotifGetListJob.perform_now options, options
        end
      end
    end
  end
end