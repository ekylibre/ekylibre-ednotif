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
            r = Identifier.where(nature: :cattling_number, value: op_response[:farm][:farm_number])
            fail 'Missing Identifier' unless r.present?

            op_response.fetch(:animals, []).each do |animal|
              identity = animal[:identity]

              begin
                # 2nd level error handling. Should not occurs as values are checked during transcoding.
                ActiveRecord::Base.transaction do
                  record = animal.where(identification_number: identity[:identification_number]).first_or_create!()

                  identity[:country_code]
                  identity[:identification_number]
                  identity[:sex]
                  identity[:race_code]
                  identity[:birth_date][:date]
                  identity[:birth_date][:witness] unless identity[:birth_date][:witness].nil?
                  identity[:work_number]
                  identity[:name]
                  identity[:cpb_filiation_status]

                  #mother
                  identity[:mother][:country_code]
                  identity[:mother][:identification_number]
                  identity[:mother][:race_code]

                  #father
                  identity[:father][:country_code]
                  identity[:father][:identification_number]
                  identity[:father][:race_code]

                  identity[:first_calving_date]

                  #birth farm number
                  identity[:farm_number]

                  identity[:origin_country_code]
                  identity[:origin_identification_number]

                  if identity[:end_of_life]
                    identity[:end_of_life_date]
                    identity[:end_of_life_witness]
                  end

                  animal.fetch(:mouvements, []).each do |mvt|
                    if mvt[:entry]
                      mvt[:entry][:entry_date]
                      mvt[:entry][:entry_reason]
                    end

                    if mvt[:exit]
                      mvt[:exit][:exit_date]
                      mvt[:exit][:exit_reason]
                    end
                  end
                end
              rescue => e
                #TODO: format errors
                logger.state = [identity[:identification_number], e.record.errors.messages].to_s
                logger.save!
              end
            end

            op_response.fetch(:buckles, []).each do |buckles|
              buckles.fetch(:buckles_serie, []).each do |serie|
                serie[:country_code]
                serie[:start_date]
                serie[:quantity]
              end
            end

          end
        end
      end
    end
  end
end