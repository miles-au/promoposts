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

  get '/auth/:provider/callback' => 'sessions#facebook'
  get 'auth/failure', to: redirect('/')
  get 'microposts/facebook_sharable_pages'
  
  delete '/logout',  to: 'sessions#destroy'

  get 'sessions/resend_activation', to: 'sessions#resend_activation'
  get 'microposts/share_to_facebook', to: 'microposts#share_to_facebook'

  get 'microposts/new'

  post '/webhooks_facebook' => 'webhooks#facebook', as: :facebook_webhooks
  get '/webhooks_facebook' => 'webhooks#challenge', as: :challenge_webhooks

  get '/accounts/edit'
  post '/accounts/edit' => 'accounts#update'

  resources :users do
    member do
      get :following, :followers
    end
  end

  get 'global_feed' => "static_pages#global_feed"
  get 'user_feed' => "static_pages#user_feed"

  resources :account_activations, only: [:edit]
  resources :password_resets,     only: [:new, :create, :edit, :update]
  resources :microposts,          only: [:create, :destroy, :show]
  resources :relationships,       only: [:create, :destroy]
end
