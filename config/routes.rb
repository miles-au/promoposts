Rails.application.routes.draw do

  get 'password_resets/new'
  get 'password_resets/edit'
  get 'sessions/new'
  get 'users/new'
  root 'static_pages#home'

  get  '/help', to: 'static_pages#help'
  get  '/contact', to: 'static_pages#contact'
  post '/contact', to: 'static_pages#contacted', as: 'contacted'
  get '/privacy_policy', to: 'static_pages#privacy_policy'
  get '/cookie_policy', to: 'static_pages#cookie_policy'
  get '/terms', to: 'static_pages#terms'

  get  '/signup',  to: 'users#new'

  get    '/login',   to: 'sessions#new'
  post   '/login',   to: 'sessions#create'

  #oauth 1
  get '/auth/:provider/callback', to: 'oauth#callback'
  get '/auth/failure', to: 'oauth#failure'

  #oauth 2
  # get '/sessions/oauth2', to: 'sessions#oauth2'
  # get '/oauth2/:provider', to: 'sessions#outh2_callback'
  
  delete '/logout',  to: 'sessions#destroy'

  get '/microposts/:id/share_micropost', to: 'microposts#share_post', as: 'share_post'
  post '/microposts/:id/share_micropost', to: 'microposts#submit_share_post'

  get '/microposts/new'

  get '/accounts/edit'
  post '/accounts/edit' => 'accounts#update'

  post '/microposts/share_to_socials'

  get '/campaigns/:id/share_campaign', to: 'campaigns#share_campaign', as: 'share_campaign'
  post '/campaigns/:id/share_campaign', to: 'campaigns#submit_share_campaign'

  # get 'users/:id/settings', to: 'users#settings', as: :user_settings
  # post 'users/:id/settings', to: 'settings#update_settings', as: :update_user_settings

  get '/unsubscribe_email', to: 'users#unsubscribe_email'
  post '/unsubscribe_email', to: 'users#unsubscribe_email_action'

  get '/resend_activation', to: 'sessions#resend_activation',  as: :sessions_resend_activation

  post '/delete_data', to: 'webhooks#delete_data'
  post '/unauthorize_facebook', to: 'webhooks#unauthorize_facebook'

  get  "/accounts/disconnect", to: "accounts#disconnect"
  get "/accounts/remove_page", to: "accounts#remove_page"

  get '/account_activations/:id/update', to: 'account_activations#update_email', as: 'update_email'

  get '/microposts/:id/download_post', to: "microposts#download_post_page", as: 'download_post_page'
  post '/microposts/:id/download_post', to: "microposts#download_post", as: 'download_post'
  get '/campaigns/:id/download_assets', to: "campaigns#download_campaign_page", as: 'download_campaign_page'
  post '/campaigns/:id/download_assets', to: "campaigns#download_assets", as: 'download_assets'

  get '/overlays', to: "overlays#show"
  post '/overlays', to: "overlays#create"
  delete '/overlays', to: "overlays#destroy"
  post '/overlays_default', to: "overlays#default_overlay"

  get '/admin_panel', to: "static_pages#admin_panel"
  get '/tracking', to: "static_pages#tracking"

  get '/prev_week', to: "scheduled_posts#prev_week"
  get '/next_week', to: "scheduled_posts#next_week"

  post '/update_topics', to: "settings#update_topics", as: "update_topics"
  post '/global_post', to: "scheduled_posts#create_global_post"
  post '/global_campaign', to: "scheduled_posts#create_global_campaign"

  post '/users/:id/update_timezone', to: "users#update_timezone", as: "update_timezone"

  get '/users/:id/onboarding', to: "onboarding#show", as: "show_onboarding"
  get '/users/:id/onboarding/next_stage', to: "onboarding#next_stage", as: "onboarding_next_stage"
  post '/users/:id/onboarding/update_user', to: "onboarding#update_user", as: "onboarding_update_user"

  get '/how_does_it_work', to: "static_pages#how_does_it_work"

  post '/accounts/:id/update_on_schedule', to: "accounts#update_on_schedule", as: "update_on_schedule"
  post '/accounts/:id/update_on_schedule_all', to: "accounts#update_on_schedule_all", as: "update_on_schedule_all"

  resources :users do
    member do
      get :following, :followers
    end
  end

  resources :account_activations, only: [:edit]
  resources :password_resets,     only: [:new, :create, :edit, :update]
  resources :microposts,          only: [:create, :destroy, :show, :update]
  resources :relationships,       only: [:create, :destroy]
  resources :tickets,             only: [:create, :destroy, :show]
  resources :campaigns
  resources :scheduled_posts

end
