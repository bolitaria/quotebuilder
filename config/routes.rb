Rails.application.routes.draw do
  resources :products, only: [ :index, :show ] do
    resources :ai_suggestions, only: [ :create ], module: false
    resource :configuration, only: [ :new, :update ], controller: "configurations"
    resources :quotes, only: [ :create ]
  end
  resources :quotes, only: [ :show ]  # para descargar PDF
  root "products#index"
end
