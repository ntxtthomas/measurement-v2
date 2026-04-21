Rails.application.routes.draw do
  root "dashboard#index"

  # ── Auth ──────────────────────────────────────────────────────────────────
  get    "/login",  to: "sessions#new",     as: :login
  post   "/login",  to: "sessions#create"
  delete "/logout", to: "sessions#destroy", as: :logout

  # ── Core Domain ──────────────────────────────────────────────────────────
  resources :organizations, only: [:index, :show]
  resources :schools,       only: [:show]
  resources :classrooms,    only: [:show]
  resources :teachers,      only: [:show]
  resources :students,      only: [:show]

  resources :observation_sessions do
    member do
      get  :finalize, action: :finalize_form
      post :finalize, action: :finalize
    end

    resources :observation_scores, only: [:create, :update]
    resources :observation_notes,  only: [:create, :update, :destroy]
  end

  resources :reports, only: [:index, :show] do
    member do
      post :regenerate
    end
  end

  # ── Engineering Dashboard ─────────────────────────────────────────────────
  namespace :engineering do
    root "dashboard#index"

    resources :phases, only: [:show] do
      resources :epics, only: [:show]
    end

    resources :tasks, only: [:update]
  end

  # ── Health check ──────────────────────────────────────────────────────────
  get "/up", to: proc { [200, {}, ["ok"]] }
end
