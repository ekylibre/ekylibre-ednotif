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
          if dataset[:farm_number] =~ /[0-9]{8}/ && dataset[:country_code]
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
            v.nil? || v.respond_to?(:empty?) && v.empty?
          end
          message.delete_if(&p)

          Ednotif::EdnotifIntegration.get_inventory(options: options, message: message).execute(logger) do |op_c|
            op_c.success do |op_response|
              ActiveRecord::Base.transaction do
                op_response.fetch(:animals, []).each do |animal|
                  # example for animal dataset
                  # {
                  #  :identity=>{:country_code=>"fr",
                  #  :identification_number=>"0332390505",
                  # :sex=>"female",
                  # :race_code=>"bos_taurus_limousine",
                  # :birth_date=>{:date=>Wed, 09 Oct 2019, :witness=>"full_date"},
                  # :work_number=>"0505",
                  # :name=>"PICHOLINE",
                  # :filiation_status=>"certified",
                  # :mother=>{:country_code=>"fr", :identification_number=>"0314723683", :race_code=>"bos_taurus_limousine"},
                  # :father=>{:country_code=>"fr", :identification_number=>"8160026685", :race_code=>"bos_taurus_limousine"},
                  # :farm_number=>"03281101",
                  # :origin_country_code=>"fr",
                  # :origin_identification_number=>"0332390505"},
                  # :mouvements=>[{:entry=>{:entry_date=>Fri, 24 Jul 2020, :entry_reason=>"purchase"}}]
                  # }
                  identity = animal[:identity]

                  item = Onoma::Variety[identity[:race_code]]
                  variety = (item ? item.name : :bos_taurus)

                  # fallbacks
                  identity[:birth_date] ||= {}
                  identity[:mother] ||= {}
                  identity[:father] ||= {}
                  identity[:sex] ||= 'female'

                  attrs = {
                    identification_number: identity[:identification_number],
                    work_number: identity[:work_number].present? ? identity[:work_number] : identity[:identification_number][-4..-1],
                    name: identity[:name] || identity[:identification_number],
                    variety: variety,
                    born_at: (identity[:birth_date] ? identity[:birth_date][:date] : nil),
                    dead_at: (identity[:end_of_life] ? identity[:end_of_life][:end_of_life_date] : nil),
                    owner: Entity.of_company,
                    birth_date_completeness: identity[:birth_date][:witness],
                    filiation_status: identity[:filiation_status].nil? ? :unknown : identity[:filiation_status],
                    birth_farm_number: identity[:farm_number],
                    first_calving_on: identity[:first_calving_date],
                    origin_country: identity[:origin_country_code],
                    origin_identification_number: identity[:origin_identification_number],
                    end_of_life_reason: identity[:end_of_life_witness],
                    country: identity[:country_code],
                    mother_country: identity[:mother][:country_code],
                    mother_identification_number: identity[:mother][:identification_number],
                    mother_variety: identity[:mother][:race_code],
                    father_country: identity[:father][:country_code],
                    father_identification_number: identity[:father][:identification_number],
                    father_variety: identity[:father][:race_code],
                    originator: logger
                  }

                  # TODO: enhance
                  if attrs[:born_at].blank? && animal.try(:[], :mouvements).collect { |mvt|
 mvt.try(:[], :entry).try(:[], :entry_date) }.compact.present?
                    attrs[:born_at] = animal[:mouvements].collect { |mvt| mvt[:entry][:entry_date] }.first
                  end

                  # 36 months for adut cow
                  age_in_days = (op_response[:generation_datetime].to_date - attrs[:born_at]).to_i
                  if age_in_days > (365 * 3)
                    pnv_to_import = "#{identity[:sex]}_adult_cow"
                  else
                    pnv_to_import = "#{identity[:sex]}_young_cow"
                  end

                  variant = ProductNatureVariant.import_from_nomenclature(pnv_to_import)
                  attrs[:variant] = variant

                  # find and update or create animal
                  record = Animal.find_by(identification_number: identity[:identification_number])
                  if record.present?
                    record.update(name: attrs[:name])
                  else
                    record = Animal.create!(attrs)
                  end

                  animal.fetch(:mouvements, []).each do |mvt|
                    mvt[:entry] ||= {}
                    mvt[:exit] ||= {}

                    if mvt[:entry].present?
                      record.movements.create!(product: record, delta: record.initial_population, started_at: mvt[:entry][:entry_date],
description: mvt[:entry][:entry_reason])
                    end
                    if mvt[:exit].present?
                      record.movements.create!(product: record, delta: -record.initial_population, started_at: mvt[:exit][:exit_date],
description: mvt[:exit][:exit_reason])
                    end
                  end

                  record.read!(:healthy, true, at: record.born_at, force: true)
                end

                # when all animals imported, set kinship
                op_response.fetch(:animals, []).each do |animal|
                  identity = animal[:identity]
                  record = Animal.find_by(identification_number: identity[:identification_number])

                  identity[:mother] ||= {}
                  identity[:father] ||= {}

                  m_id_number = identity[:mother][:identification_number] || nil
                  f_id_number = identity[:father][:identification_number] || nil

                  mother = Animal.find_by(identification_number: m_id_number) if m_id_number
                  father = Animal.find_by(identification_number: f_id_number ) if f_id_number

                  if record && mother.present? && !record.mother.present?
                    record.links.create!(nature: :mother, linked: mother)
                  end

                  if record && father.present? && !record.father.present?
                    record.links.create!(nature: :father, linked: father)
                  end
                end

                op_response.fetch(:buckles, []).each do |buckles|
                  buckles.fetch(:buckles_serie, []).each do |serie|
                    # TODO
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
              raise Ednotif::ServiceError.new(response)
            end
          end
        end
      rescue => e
        if e.is_a?(ActionIntegration::ServiceNotIntegrated) || e.is_a?(ActionIntegration::IntegrationParameterEmpty)
          logger.update_columns(state: :aborted)
          interpolations = { message: :this_service_is_not_activated.t(scope: 'notifications.messages'), target: nil }
        else
          logger.update_columns(state: :errored)
          interpolations = { message: e.message.t(scope: 'notifications.messages', default: e.message),
target: e.respond_to?(:record) && e.record.identification_number ? e.record.identification_number : nil }
        end
        error_message = logger.notify(:synchronization_operation_failed, interpolations, level: :error)
        logger.update_columns(notification_id: error_message)
      end
    end
  end
end
