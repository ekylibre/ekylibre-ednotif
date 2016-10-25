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


        p = proc do |_, v|
          v.delete_if(&p) if v.respond_to? :delete_if
          v.nil? || v.respond_to?(:'empty?') && v.empty?
        end
        message.delete_if(&p)

        Ednotif::EdnotifIntegration.get_list(options: options, message: message).execute(logger) do |op_c|
          op_c.success do |op_response|
            # r = Identifier.where(nature: :cattling_number, value: op_response[:farm][:farm_number])
            # fail 'Missing Identifier' unless r.present?

            op_response.fetch(:animals, []).each do |animal|
              identity = animal[:identity]

              begin
                # 2nd level error handling. Should not occurs as values are checked during transcoding.
                ActiveRecord::Base.transaction do

                  item = Nomen::Variety[identity[:race_code]]
                  variety = (item ? item.name : :bos_taurus)

                  attrs = {
                    identification_number: identity[:identification_number],
                    work_number: identity[:work_number],
                    name: identity[:name],
                    variety: variety,
                    initial_population: 1.0,
                    initial_born_at: (identity[:birth_date] ? identity[:birth_date][:date] : nil),
                    initial_dead_at: (identity[:end_of_life] ? identity[:end_of_life][:end_of_life_date] : nil),
                    owner: Entity.of_company,
                  }

                  # 36 months
                  variant = ProductNatureVariant.import_from_nomenclature(((op_response[:generation_datetime].to_date - attrs[:initial_born_at]).to_i > 365*3) ? "#{identity[:sex]}_adult_cow" : "#{identity[:sex]}_young_cow")
                  attrs.merge!({variant: variant})

                  #TODO
                  # storage, memberships


                  record = Animal.where(identification_number: identity[:identification_number]).first_or_create!(attrs)
                  record.read!(:healthy, true, at: attrs[:initial_born_at])

                  record.read!(:witness, identity[:birth_date][:witness], at: attrs[:initial_born_at], force: true) unless identity[:birth_date][:witness].nil?
                  record.read!(:cpb_filiation_status, identity[:cpb_filiation_status], at: attrs[:initial_born_at], force: true) unless identity[:cpb_filiation_status].nil?
                  record.read!(:birth_date, identity[:birth_date][:date], at: attrs[:initial_born_at], force: true) unless identity[:birth_date][:date].nil?
                  record.read!(:birth_farm_number, identity[:farm_number], at: attrs[:initial_born_at], force: true) unless identity[:farm_number].nil?
                  record.read!(:first_calving_date, identity[:first_calving_date], at: attrs[:initial_born_at], force: true) unless identity[:first_calving_date].nil?
                  record.read!(:origin_country_code, identity[:origin_country_code], at: attrs[:initial_born_at], force: true) unless identity[:origin_country_code].nil?
                  record.read!(:origin_identification_number, identity[:origin_identification_number], at: attrs[:initial_born_at], force: true) unless identity[:origin_identification_number].nil?
                  record.read!(:end_of_life_witness, identity[:end_of_life_witness], at: attrs[:initial_born_at], force: true) unless identity[:end_of_life_witness].nil?
                  record.read!(:country_code, identity[:country_code], at: attrs[:initial_born_at], force: true) unless identity[:country_code].nil?

                  #mother
                   record.read!(:mother_country_code, identity[:mother][:country_code], force: true) unless identity[:mother][:country_code].nil?
                   record.read!(:mother_identification_number, identity[:mother][:identification_number], force: true) unless identity[:mother][:identification_number].nil?
                   record.read!(:mother_race_code, identity[:mother][:race_code], force: true) unless identity[:mother][:race_code].nil?

                  #father
                   record.read!(:father_country_code, identity[:father][:country_code], force: true) unless identity[:father][:country_code].nil?
                   record.read!(:father_identification_number, identity[:father][:identification_number], force: true) unless identity[:father][:identification_number].nil?
                   record.read!(:father_race_code, identity[:father][:race_code], force: true) unless identity[:father][:race_code].nil?



                  animal.fetch(:mouvements, []).each do |mvt|
                    if mvt[:entry]
                      record.read!(:entry_date, mvt[:entry][:entry_date], at: mvt[:entry][:entry_date], force: true) unless mvt[:entry][:entry_date].nil?
                      record.read!(:entry_reason, mvt[:entry][:entry_reason], at: mvt[:entry][:entry_date], force: true) unless mvt[:entry][:entry_reason].nil?
                    end

                    if mvt[:exit]
                      record.read!(:exit_date, mvt[:entry][:exit_date], at: mvt[:entry][:exit_date], force: true) unless mvt[:entry][:exit_date].nil?
                      record.read!(:exit_reason, mvt[:entry][:exit_reason], at: mvt[:entry][:exit_date], force: true) unless mvt[:entry][:exit_reason].nil?
                    end
                  end

                end
              rescue => e
                #TODO: format errors
                binding.pry
                logger.state = [identity[:identification_number], e.record.errors.messages].to_s if e.respond_to?(:record)
                logger.save!
              end
            end

            op_response.fetch(:buckles, []).each do |buckles|
              buckles.fetch(:buckles_serie, []).each do |serie|
                #TODO
                # serie[:country_code]
                # serie[:start_date]
                # serie[:quantity]
              end
            end

          end
        end
      end
    end
  end
end