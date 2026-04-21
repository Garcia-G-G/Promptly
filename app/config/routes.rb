Rails.application.routes.draw do
  devise_for :users

  root "marketing#index"

  resources :workspaces, param: :slug, only: [ :new, :create, :show ] do
    resources :projects, param: :slug, only: [ :index, :show, :new, :create ] do
      resources :prompts, only: [ :new, :create ], controller: "web/project_prompts"
    end

    # Web dashboard
    namespace :web do
      resources :prompts, only: [ :index, :show ], param: :slug do
        get :diff, on: :member
        post :promote, on: :member
        resources :versions, only: [ :new, :create ], controller: "prompt_versions"
      end
      resources :experiments, only: [ :index ]
      resources :logs, only: [ :index ]
      resources :datasets, only: [ :index ]
      resources :scorers, only: [ :index ]
      resources :eval_runs, only: [ :index ]
      resource :settings, only: [ :show ]
    end
  end

  namespace :api do
    namespace :webhooks do
      post "stripe", to: "stripe#create"
      post "github", to: "github#create"
    end

    namespace :v1 do
      resources :prompts, param: :slug, only: [ :index, :create, :show ] do
        member do
          post :resolve
          post :log
        end
        resources :versions, only: [ :create ], controller: "prompt_versions"
        post :promote, on: :member
        resources :experiments, only: [ :index, :create ], controller: "experiments"
      end

      resources :experiments, only: [ :update ] do
        member do
          post :advance_canary
          get :stats
        end
      end

      resources :scorers, only: [ :index, :create, :update, :destroy ]

      resources :datasets, only: [ :index, :create, :show, :destroy ] do
        post :rows, on: :member, action: :import_rows
      end

      resources :eval_runs, only: [ :index, :show, :create ]

      resources :prompt_versions, only: [] do
        resource :security_scan, only: [ :show, :create ]
      end
    end
  end

  if defined?(MissionControl::Jobs)
    authenticate :user do
      mount MissionControl::Jobs::Engine, at: "/jobs"
    end
  end

  get "up" => "rails/health#show", as: :rails_health_check
end
