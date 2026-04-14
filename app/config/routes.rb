Rails.application.routes.draw do
  devise_for :users

  root "marketing#index"

  resources :workspaces, param: :slug, only: [ :new, :create, :show ] do
    resources :projects, param: :slug, only: [ :index, :show, :new, :create ]
  end

  namespace :api do
    namespace :v1 do
      post "prompts/:slug/resolve", to: "prompts#resolve", as: :prompt_resolve
      post "prompts/:slug/log",     to: "prompts#log",     as: :prompt_log
    end
  end

  if defined?(MissionControl::Jobs)
    authenticate :user do
      mount MissionControl::Jobs::Engine, at: "/jobs"
    end
  end

  get "up" => "rails/health#show", as: :rails_health_check
end
