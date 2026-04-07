Rails.application.routes.draw do
  devise_for :users, controllers: {
    sessions: 'users/sessions'
  }
  get "dashboard", to: "dashboard#index", as: :dashboard
  get "documents/tags", to: "documents#tags_search", as: :documents_tags_search
  get "chat", to: "chat#index", as: :chat
  resource :settings, only: %i[show update]

  resources :folders do
    resources :documents, shallow: true, only: %i[index create show destroy]
  end
  resources :documents, only: [] do
    member do
      patch :move
      patch :add_tag
      patch :replace_tag
      delete :remove_tag
    end
  end
  resources :groups do
    resources :memberships, controller: "group_memberships", only: %i[create destroy]
  end
  resources :subscriptions
  resources :users
  resources :accounts do
    resources :conversations, only: %i[index show create destroy] do
      resources :messages, only: [:create]
    end
  end
  resources :plans
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  root "dashboard#index"
end
