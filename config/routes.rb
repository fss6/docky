Rails.application.routes.draw do
  devise_for :users, controllers: {
    sessions: 'users/sessions'
  }
  authenticated :user do
    root "dashboard#index", as: :authenticated_root
  end
  unauthenticated do
    root "landing#index"
  end

  get "landing", to: "landing#index", as: :landing
  get "privacidade", to: "landing#privacy", as: :privacy
  get "dashboard", to: "dashboard#index", as: :dashboard
  get "documents/tags", to: "documents#tags_search", as: :documents_tags_search
  get "documents/search", to: "documents#term_search", as: :documents_term_search
  get "chat", to: "chat#index", as: :chat
  get "wiki", to: "wiki_pages#index", as: :wiki
  get "wiki/log", to: "wiki_pages#log", as: :wiki_log
  get "wiki/lint_report", to: "wiki_pages#lint_report", as: :wiki_lint_report
  get "wiki/:slug", to: "wiki_pages#show", as: :wiki_page, constraints: { slug: /[^\/]+(?:\/[^\/]+)*/ }
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

end
