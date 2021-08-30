require "sidekiq/web"

Liveinspired::Application.routes.draw do
  root to: "home#index"

  mount Sidekiq::Web => "/sidekiq"
  mount RailsAdmin::Engine => "/admin", :as => "rails_admin"

  devise_for :users

  resources :channels do
    member do
      get :list_subscribers
      get :messages_report
    end

    resources :messages do
      member do
        post :broadcast
        post :move_up
        post :move_down
        get :responses
      end
      collection do
        get :select_import
        post :import
      end

      resources :response_actions do
        collection do
          get :select_import
          post :import
        end
      end
    end
  end

  post "channels/:channel_id/add_subscriber/:id" => "channels#add_subscriber", :as => "channel_add_subscriber"
  post "channels/:channel_id/remove_subscriber/:id" => "channels#remove_subscriber", :as => "channel_remove_subscriber"

  resources :channel_groups, except: [:index] do
    member do
      get  :messages_report
      get  :clone
      post :copy
      get  :messages_report
    end
  end

  post "channel_groups/:channel_group_id/remove_channel/:id" => "channel_groups#remove_channel", :as => "channel_group_remove_channel"

  resources :users
  resources :subscribers

  resources :subscriber_activities, except: %i(new create destroy)

  resources :downloads, only: [:index]
  resources :service_identifiers, only: [:index]

  match "subscribe/:channel_group_id" => "home#new_web_subscriber", :via => %i(get post)
  get "thank_you" => "home#sign_up_success"
  post "twilio" => "twilio#callback"

  match "help/user_show", via: :all
  match "help/edit_channel", via: :all
  match "help/edit_message", via: :all
  match "help/index_channels", via: :all
  match "help/edit_response_action", via: :all
  match "help/glossary", via: :all
end
