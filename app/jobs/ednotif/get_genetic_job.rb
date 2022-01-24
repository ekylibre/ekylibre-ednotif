module Ednotif
  class GetGeneticJob < ActiveJob::Base
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
            start_date: dataset[:start_date]
          }

          p = proc do |_, v|
            v.delete_if(&p) if v.respond_to? :delete_if
            v.nil? || v.respond_to?(:'empty?') && v.empty?
          end
          message.delete_if(&p)

          Ednotif::EdnotifIntegration.get_genetic(options: options, message: message).execute(logger) do |op_c|
            op_c.success do |op_response|
              ActiveRecord::Base.transaction do
                 puts op_response.inspect.red
                logger.notify(:synchronization_operation_finished_successfully)
                logger.update_columns(state: :finished, finished_at: Time.zone.now)
              end
            end

            op_c.error do |response|
              raise Ednotif::ServiceError, response
            end
          end
        end
      rescue => e
        if e.is_a?(ActionIntegration::ServiceNotIntegrated) || e.is_a?(ActionIntegration::IntegrationParameterEmpty)
          logger.update_columns(state: :aborted)
          interpolations = { message: :this_service_is_not_activated.t(scope: 'notifications.messages'), target: nil }
        else
          logger.update_columns(state: :errored)
          interpolations = { message: e.message.t(scope: 'notifications.messages', default: e.message), target: e.respond_to?(:record) && e.record.identification_number ? e.record.identification_number : nil }
        end
        error_message = logger.notify(:synchronization_operation_failed, interpolations, level: :error)
        logger.update_columns(notification_id: error_message)
      end
    end
  end
end
