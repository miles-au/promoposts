Rails.application.routes.draw do

  resources :campaigns
  get 'password_resets/new'
  get 'password_resets/edit'
  get 'sessions/new'
  get 'users/new'
  root 'static_pages#home'

  get  '/help', to: 'static_pages#help'
  get  '/contact', to: 'static_pages#contact'
  post  '/contact', to: 'static_pages#contacted', as: 'contacted'
  get '/privacy_policy', to: 'static_pages#privacy_policy'
  get '/cookie_policy', to: 'static_pages#cookie_policy'
  get '/terms', to: 'static_pages#terms'
  get '/what_is_autoshare', to: 'static_pages#what_is_autoshare'

  get  '/signup',  to: 'users#new'

  get    '/login',   to: 'sessions#new'
  post   '/login',   to: 'sessions#create'

  get '/social_login', to: 'sessions#social_new'

  #oauth 1
  get '/auth/:provider/callback', to: 'sessions#callback', as: 'sessions_callback'
  get '/auth/failure', to: 'oauth#failure', as: 'oauth_failure'

  #oauth 2
  get '/sessions/oauth2', to: 'sessions#oauth2'
  get '/oauth2/:provider', to: 'sessions#outh2_callback'
  
  delete '/logout',  to: 'sessions#destroy'

  get 'sessions/resend_activation', to: 'sessions#resend_activation'
  get 'microposts/share_to_socials', to: 'microposts#share_to_socials', as: 'share_to_socials'

  get 'microposts/new'

  post '/webhooks_facebook' => 'webhooks#facebook', as: :facebook_webhooks
  get '/webhooks_facebook' => 'webhooks#challenge', as: :challenge_webhooks

  get '/accounts/edit'
  post '/accounts/edit' => 'accounts#update'

  get 'static_pages/change_grid_view'
  post '/microposts/share_to_socials'

  get 'users/add_product' => 'lists#add_product'
  post 'users/add_product' => 'lists#submit_product'

  get 'users/delete_product' => 'lists#delete_product'

  get 'users/:id/settings', to: 'users#settings', as: :user_settings
  post 'users/:id/settings', to: 'settings#update_settings', as: :update_user_settings

  get 'users/:id/lists', to: 'lists#show', as: :show_lists
  get 'users/create_list', to: 'lists#create', as: :create_list
  post 'users/create_list', to: 'lists#submit', as: :submit_list
  get 'users/delete_list', to: 'lists#delete', as: :delete_list

  get 'unsubscribe_email', to: 'users#unsubscribe_email'
  post 'unsubscribe_email', to: 'users#unsubscribe_email_action'

  post 'delete_data', to: 'webhooks#delete_data'
  post 'unauthorize_facebook', to: 'webhooks#unauthorize_facebook'

  get  "accounts/disconnect", to: "accounts#disconnect"

  get 'comments/reply', to: 'comments#reply'
  get 'comments/mark_top_comment', to: 'microposts#mark_top_comment', as: :mark_top_comment

  get '/decline_wizard', to: 'static_pages#decline_wizard', as: 'decline_wizard'

  get '/account_activations/:id/update', to: 'account_activations#update_email', as: 'update_email'

  get '/notifications/all', to: 'notifications#all'

  get '/notifications', to: 'notifications#mark_read'

  get '/submit_vote', to: 'votes#submit_vote'

  get '/microposts/:id/download_picture', to: "microposts#download_picture", as: 'download_picture'
  get '/campaigns/:id/download_assets', to: "campaigns#download_assets", as: 'download_assets'

  get '/landing_page', to: "static_pages#landing_page"

  resources :users do
    member do
      get :following, :followers
    end
  end

  resources :account_activations, only: [:edit]
  resources :password_resets,     only: [:new, :create, :edit, :update]
  resources :microposts,          only: [:create, :destroy, :show, :update]
  resources :relationships,       only: [:create, :destroy]
  resources :events,              only: [:destroy]
  resources :tickets,             only: [:create, :destroy, :show]
  resources :comments
  resources :campaigns,           only: [:create, :destroy, :show]

end
