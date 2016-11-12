module Ednotif
  class GetInventoryJob < ActiveJob::Base
    queue_as :default

    def perform(*args)
      dataset = args.extract_options!
      logger = SynchronizationOperation.find(dataset.delete(:synchronization_operation_id))

      logger.notify(:synchronization_operation_in_progress)
      logger.update_columns(state: :in_progress)


      dataset[:start_date] ||= Date.today
      dataset[:get_stock] ||= false
      dataset[:country_code] ||= 'FR'

      begin

        Ednotif::EdnotifIntegration.authenticate_and_do logger do

          integration ||= Ednotif::EdnotifIntegration.fetch!


          options = {
              globals: {
                  wsdl: integration.parameters['business_wsdl']
              }
          }

          dataset[:farm_number] ||= integration.parameters['cattling_number']
          if dataset[:farm_number] =~ /[0-9]{8}/ and dataset[:country_code]
            dataset[:farm_number] = [dataset[:country_code], dataset[:farm_number]].join
          end


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


          p = proc do |_, v|
            v.delete_if(&p) if v.respond_to? :delete_if
            v.nil? || v.respond_to?(:'empty?') && v.empty?
          end
          message.delete_if(&p)

          Ednotif::EdnotifIntegration.get_inventory(options: options, message: message).execute(logger) do |op_c|
            op_c.success do |op_response|

              ActiveRecord::Base.transaction do

                op_response.fetch(:animals, []).each do |animal|
                  identity = animal[:identity]

                  item = Nomen::Variety[identity[:race_code]]
                  variety = (item ? item.name : :bos_taurus)

                  attrs = {
                      identification_number: identity[:identification_number],
                      work_number: identity[:work_number].present? ? identity[:work_number] : identity[:identification_number][-4..-1],
                      name: identity[:name],
                      variety: variety,
                      initial_population: 1.0,
                      born_at: (identity[:birth_date] ? identity[:birth_date][:date] : nil),
                      dead_at: (identity[:end_of_life] ? identity[:end_of_life][:end_of_life_date] : nil),
                      owner: Entity.of_company,
                  }

                  # fallbacks
                  identity[:birth_date] ||= {}
                  identity[:mother] ||= {}
                  identity[:father] ||= {}
                  identity[:sex] ||= :female


                  #TODO enhance
                  attrs[:initial_born_at] = animal[:mouvements].collect { |mvt| mvt[:entry][:entry_date] }.first if attrs[:initial_born_at].blank? and animal.try(:[], :mouvements).collect { |mvt| mvt.try(:[], :entry).try(:[], :entry_date) }.compact.present?

                  # 36 months
                  variant = ProductNatureVariant.import_from_nomenclature(((op_response[:generation_datetime].to_date - attrs[:initial_born_at]).to_i > 365*3) ? "#{identity[:sex]}_adult_cow" : "#{identity[:sex]}_young_cow")
                  attrs.merge!({variant: variant})


                  record = Animal.where(identification_number: identity[:identification_number]).first_or_create!(attrs)


                  animal.fetch(:mouvements, []).each do |mvt|

                    mvt[:entry] ||= {}
                    mvt[:exit] ||= {}

                    if mvt[:entry].present?
                      record.movements.create!(product: record, delta: record.initial_population, started_at: mvt[:entry][:entry_date])
                      record.initial_movement = record.movements.first

                      record.born_at = mvt[:entry][:entry_date] if record.born_at.blank?

                      record.save!

                      record.read!(:entry_date, mvt[:entry][:entry_date], at: record.born_at, force: true) unless mvt[:entry][:entry_date].nil?
                      record.read!(:entry_reason, mvt[:entry][:entry_reason], at: record.born_at, force: true) unless mvt[:entry][:entry_reason].nil?
                    end

                    if mvt[:exit].present?
                      record.movements.create!(product: record, delta: -record.initial_population, started_at: mvt[:entry][:exit_date])

                      record.read!(:exit_date, mvt[:entry][:exit_date], at: record.born_at, force: true) unless mvt[:entry][:exit_date].nil?
                      record.read!(:exit_reason, mvt[:entry][:exit_reason], at: record.born_at, force: true) unless mvt[:entry][:exit_reason].nil?
                    end
                  end

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

                # when all animals imported, set kinship
                op_response.fetch(:animals, []).each do |animal|


                  identity = animal[:identity]
                  animal = Animal.find_by(identification_number: identity[:identification_number])

                  identity[:mother] ||= {}
                  identity[:father] ||= {}

                  if animal and identity[:mother][:identification_number] and mother = Animal.find_by(identification_number: identity[:mother][:identification_number])
                    animal.initial_mother = mother
                  end

                  if animal and identity[:father][:identification_number] and father = Animal.find_by(identification_number: identity[:father][:identification_number])
                    animal.initial_father = father
                  end

                  animal.save!

                end

                op_response.fetch(:buckles, []).each do |buckles|
                  buckles.fetch(:buckles_serie, []).each do |serie|
                    #TODO
                    # serie[:country_code]
                    # serie[:start_date]
                    # serie[:quantity]
                  end
                end

                logger.notify(:synchronization_operation_finished_successfully)
                logger.update_columns(state: :finished, finished_at: Time.zone.now)
              end
            end

            op_c.error do |response|
              fail Ednotif::ServiceError, response
            end
          end
        end
      rescue => e
        if e.is_a?(ActionIntegration::ServiceNotIntegrated) or e.is_a?(ActionIntegration::IntegrationParameterEmpty)
          logger.update_columns(state: :aborted)
          interpolations = {message: :this_service_is_not_activated.t(scope: 'notifications.messages'), target: nil}
        else
          logger.update_columns(state: :errored)
          interpolations = {message: e.message.t(scope: 'notifications.messages', default: e.message), target: (e.respond_to?(:record) and e.record.identification_number) ? e.record.identification_number : nil }
        end
        error_message = logger.notify(:synchronization_operation_failed, interpolations, level: :error)
        logger.update_columns(notification_id: error_message)
      end
    end
  end
end