module Backend
  class SynchronizationOperationsController < Backend::BaseController
    # manage_restfully

    def index
    end

    def show
      @synchronization_operation = SynchronizationOperation.find(params[:id])
    end

    list order: { created_at: :desc } do |t|
      t.column :created_at
      t.column :operation_name, url: true
      t.column :state
      t.column :status
    end


    list(:calls, conditions: { source_id: 'params[:id]'.c }, order: { created_at: :desc }) do |t|
      t.column :created_at
      t.column :name
      t.column :state
      t.column :arguments
    end


    ### operations
    def import_cattling_inventory(options = {})
      current_user.notify :synchronization_operation_in_progress, operation_name: "enumerize.synchronization_operation.operation_name.#{:get_inventory}".t
      Ekylibre::Hook.publish :get_inventory, options
    end
  end
end
