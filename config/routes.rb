Rails.application.routes.draw do
  resources :products, only: [:index, :show] do
    resource :configuration, only: [:new, :update], controller: "configurations"
    resources :quotes, only: [:create]
  end
  resources :quotes, only: [:show]  # para descargar PDF
  root "products#index"
end
