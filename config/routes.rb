Rails.application.routes.draw do
  # Prefix Devise so POST /users stays reserved for UsersController#create.
  # (Default Devise registration also posts to /users and would shadow resources :users.)
  devise_for :users, path: "auth", controllers: {
    sessions: "users/sessions",
    passwords: "users/passwords",
    registrations: "users/registrations"
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
  get "wallet", to: "wallets#index", as: :wallet
  get "collection", to: "collection_panel#index", as: :collection_panel
  resources :clients, except: [:destroy] do
    member do
      get :summary
      post :archive
      post :unarchive
      post :open_period, to: "clients/periods#create"
      patch :close_period, to: "clients/periods#close"
      patch :reopen_period, to: "clients/periods#reopen"
    end
    resource :onboarding_activation, only: :create, module: :clients
    resource :onboarding_reopen, only: :create, module: :clients
    resources :onboarding_checklist_items, only: %i[index create update destroy], module: :clients do
      member do
        patch :mark_received
        patch :mark_pending
      end
    end
    resources :onboarding_upload_invites, only: [:create], module: :clients
    resources :documents, only: %i[index create destroy], module: :clients do
      member do
        patch :link
        patch :unlink
      end
    end
    resources :checklist_items, only: %i[index create], module: :clients do
      collection do
        post :sync_to_month
      end
    end
    resources :competency_checklist_items, only: [], module: :clients do
      member do
        patch :mark_validated
        patch :mark_pending
      end
    end
    resources :upload_invites, only: [:create] do
      member do
        post :send_email, to: "clients/upload_invite_emails#create"
      end
    end
    resources :folders, only: %i[index show create update destroy], module: :clients do
      collection do
        get :drawer_empty
      end
      resources :documents, only: %i[create destroy], controller: "folder_documents"
    end
  end
  resources :upload_invites, only: [] do
    member do
      patch :revoke
    end
  end
  resources :institutions
  get "documents/tags", to: "documents#tags_search", as: :documents_tags_search
  get "documents/search", to: "documents#term_search", as: :documents_term_search
  get "chat", to: "chat#index", as: :chat
  get "wiki", to: "wiki_pages#index", as: :wiki
  get "audit", to: "audits#index", as: :audits
  get "wiki/log", to: "wiki_pages#log", as: :wiki_log
  get "wiki/lint_report", to: "wiki_pages#lint_report", as: :wiki_lint_report
  delete "wiki/:slug", to: "wiki_pages#destroy", constraints: { slug: /[^\/]+(?:\/[^\/]+)*/ }
  get "wiki/:slug", to: "wiki_pages#show", as: :wiki_page, constraints: { slug: /[^\/]+(?:\/[^\/]+)*/ }
  resource :settings, only: :show
  resource :platform_settings, only: %i[show update], path: "sistema/plataforma" do
    post :regenerate_whatsapp_verify_token
    post :send_test_email
    get :collection_dispatches, path: "envios", to: "platform_collection_dispatches#index"
    get "envios/:id", to: "platform_collection_dispatches#show", as: :platform_collection_dispatch
  end
  resource :profile, only: %i[edit update]
  resource :account_profile, only: %i[edit update]
  namespace :settings do
    resource :permissions, only: %i[show update]
    resource :ai_settings, only: %i[edit update]
    resource :upload_share, only: %i[edit update], controller: "upload_shares"
    resource :onboarding_share, only: %i[edit update], controller: "onboarding_shares"
    resource :collection_ladder, only: %i[edit update], controller: "collection_ladders" do
      post :preview_email
      post :send_test_email
    end
    resources :onboarding_templates, only: %i[index show new create edit update destroy]
  end

  get "folders", to: "legacy_folders_redirect#index", as: :folders
  get "folders/new", to: "legacy_folders_redirect#new", as: :new_folder
  get "folders/:id", to: "legacy_folders_redirect#show", as: :folder, constraints: { id: /\d+/ }
  get "folders/:id/edit", to: "legacy_folders_redirect#edit", as: :edit_folder, constraints: { id: /\d+/ }

  resources :documents, only: %i[show destroy] do
    member do
      patch :move
      patch :add_tag
      patch :replace_tag
      delete :remove_tag
    end
  end
  get "portal/:token/upload", to: "public_folder_uploads#show", as: :public_folder_upload
  post "portal/:token/upload", to: "public_folder_uploads#create"
  get "portal/:token/onboarding", to: "public_folder_uploads#onboarding", as: :public_onboarding_upload
  post "portal/:token/onboarding", to: "public_folder_uploads#onboarding_upload"
  post "portal/:token/onboarding/extra", to: "public_folder_uploads#onboarding_extra_upload", as: :public_onboarding_extra_upload
  get "collection/unsubscribe", to: "collection/unsubscribes#show", as: :collection_unsubscribe
  get "webhooks/whatsapp", to: "whatsapp/webhooks#verify"
  post "webhooks/whatsapp", to: "whatsapp/webhooks#receive"
  resources :groups do
    resources :memberships, controller: "group_memberships", only: %i[create destroy]
  end
  resources :subscriptions
  resources :users do
    member do
      post :enable
    end
  end
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
