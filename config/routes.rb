Rails.application.routes.draw do
  root "products#index"
  resources :products, only: [:index, :edit, :show]
  resources :users , only: [:new,:show]
  resources :user_profiles, only: [:new, :create, :edit, :update]
  resources :signups, only: [:index, :new, :show]
  resources :cards, only: [:index,:new]
end
