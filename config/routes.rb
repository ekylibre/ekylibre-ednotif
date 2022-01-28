Rails.application.routes.draw do
  namespace :backend do
    resources :synchronization_operations do
      collection do
        get :list
        get :list_calls
        get :list_targets
        post :import_cattling_inventory
        get :clean_animals
      end
    end
  end
end
