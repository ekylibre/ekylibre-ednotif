module Ednotif
  class EdnotifCreateCattleEntranceJob < ActiveJob::Base
    queue_as :default

    def perform(*args)
      operation_name = :create_cattle_entrance.freeze
      logger = SynchronizationOperation.create!(operation_name: operation_name)

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

        p = proc do |_, v|
          v.delete_if(&p) if v.respond_to? :delete_if
          v.nil? || v.respond_to?(:'empty?') && v.empty?
        end
        message.delete_if(&p)


        Ednotif::EdnotifIntegration.create_cattle_entrance(options: options, message: message).execute(logger) do |op_c|
          op_c.success do |op_response|
            ActiveRecord::Base.transaction do
              begin
                animal = op_response[:particular_response]
                animal = animal[:validated_entry] || {}
                identity = animal[:identity]

                record = Animal.find_by(identification_number: identity[:identification_number])

                if record and animal[:entry_mouvement] and animal[:entry_mouvement].key? :entry_date
                  record.read!(:entry_date, animal[:entry_mouvement][:entry_date], at: animal[:entry_mouvement][:entry_date], force: true) unless animal[:entry_mouvement][:entry_date].nil?
                  record.read!(:entry_reason, animal[:entry_mouvement][:entry_reason], at: animal[:entry_mouvement][:entry_date], force: true) unless animal[:entry_mouvement][:entry_reason].nil?

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
                  }.delete_if(&p).each do |k, v|
                    record.read!(k, v, at: record.born_at, force: true)
                  end
                end

              rescue => e
                #TODO: format errors
                logger.state = :errored
                logger.status = [identity[:identification_number], e.record.errors.messages].to_s if e.respond_to?(:record)
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

            logger.state = :errored
            logger.status = errors.to_s
            logger.save!
          end

          op_c.error do |op_response|
            logger.state = :errored
            logger.status = op_response
            logger.save!
          end

        end
      end
    end
  end
end