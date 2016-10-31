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
                    country_code: dataset[:country_code],
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

        Ednotif::EdnotifIntegration.create_cattle_exit(options: options, message: message).execute(logger) do |op_c|
          op_c.success do |op_response|

            ActiveRecord::Base.transaction do
              begin
                animal = op_response[:particular_response]
                identity = animal[:identity]

                record = Animal.find_by(identification_number: identity[:identification_number])

                if record and animal[:exit_mouvement] and animal[:exit_mouvement].key? :exit_date
                  record.read!(:exit_date, animal[:exit_mouvement][:exit_date], at: animal[:exit_mouvement][:exit_date], force: true) unless animal[:exit_mouvement][:exit_date].nil?
                  record.read!(:exit_reason, animal[:exit_mouvement][:exit_reason], at: animal[:exit_mouvement][:exit_date], force: true) unless animal[:exit_mouvement][:exit_reason].nil?


                  # fallbacks
                  identity[:birth_date] ||= {}
                  identity[:mother] ||= {}
                  identity[:father] ||= {}
                  identity[:sex] ||= :female

                  {
                      healthy: true,
                      witness: identity[:birth_date][:witness],
                      cpb_filiation_status: identity[:cpb_filiation_status],
                      birth_date: identity[:birth_date][:date],
                      birth_farm_number: identity[:farm_number],
                      first_calving_date: identity[:first_calving_date],
                      origin_country_code: identity[:origin_country_code],
                      origin_identification_number: identity[:origin_identification_number],
                      end_of_life_witness: identity[:end_of_life_witness],
                      country_code: identity[:country_code],
                      mother_country_code: identity[:mother][:country_code],
                      mother_identification_number: identity[:mother][:identification_number],
                      mother_race_code: identity[:mother][:race_code],
                      father_country_code: identity[:father][:country_code],
                      father_identification_number: identity[:father][:identification_number],
                      father_race_code: identity[:father][:race_code]
                  }.each do |k, v|
                    record.read!(k, v, at: record.born_at, force: true) unless v.nil?
                  end

                end

              rescue => e
                #TODO: format errors
                logger.state = [identity[:identification_number], e.record.errors.messages].to_s if e.respond_to?(:record)
                logger.save!
              end
            end
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