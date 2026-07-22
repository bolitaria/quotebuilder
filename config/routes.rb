Rails.application.routes.draw do
  resources :products, only: [:index, :show]
  resources :products, only: [] do
    resource :configuration, only: [:new, :update], controller: "configurations"
  end
  root "products#index"
end
