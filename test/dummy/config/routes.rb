Rails.application.routes.draw do
  resources :doors do
    member do
      get :open
      get :change
    end
  end
end
