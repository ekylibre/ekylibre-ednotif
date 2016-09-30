module Backend
  class EdnotifLoggersController < Backend::BaseController
    # manage_restfully

    def index
    end

    def show
      @ednotif_logger = EdnotifLogger.find(params[:id])
    end

    list order: { created_at: :desc } do |t|
      t.column :created_at
      t.column :operation_name, url: true
      t.column :state
    end


    list(:calls, conditions: { source_id: 'params[:id]'.c }, order: { created_at: :desc }) do |t|
      t.column :created_at
      t.column :name
      t.column :state
      t.column :arguments
    end
  end
end
