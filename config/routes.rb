Rails.application.routes.draw do

  get 'password_resets/new'
  get 'password_resets/edit'
  get 'sessions/new'
  get 'users/new'
  root 'static_pages#home'

  get  '/help', to: 'static_pages#help'
  get  '/contact', to: 'static_pages#contact'

  get  '/signup',  to: 'users#new'

  get    '/login',   to: 'sessions#new'
  post   '/login',   to: 'sessions#create'

  get 'microposts/facebook_sharable_pages'
  get 'microposts/linkedin_sharable_pages'
  get 'microposts/instagram_sharable_pages'

  get '/auth/:provider/callback', to: 'sessions#callback', as: 'sessions_callback'
  get '/auth/failure', to: 'oauth#failure', as: 'oauth_failure'
  
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

  resources :users do
    member do
      get :following, :followers
    end
  end

  resources :account_activations, only: [:edit]
  resources :password_resets,     only: [:new, :create, :edit, :update]
  resources :microposts,          only: [:create, :destroy, :show]
  resources :relationships,       only: [:create, :destroy]
end
