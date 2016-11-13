module Backend
  class SynchronizationOperationsController < Backend::BaseController
    # manage_restfully

    def index
    end

    def show
      @synchronization_operation = SynchronizationOperation.find(params[:id])
    end

    def clean_animals
      Animal.find_each do |animal|
        animal.destroy if animal.destroyable?
      end
      redirect_to backend_animals_path
    end

    list order: { created_at: :desc } do |t|
      t.column :created_at
      t.column :operation_name, url: true
      t.column :state
      t.column :human_message
    end


    list(:calls, conditions: { source_id: 'params[:id]'.c }, order: { created_at: :desc }) do |t|
      t.column :created_at
      t.column :name
      t.column :state
      t.column :arguments
    end


    ### operations
    def import_cattling_inventory(options = {})
      SynchronizationOperation.run(:get_inventory, options)
    end
  end
end
