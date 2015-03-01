Rails.application.routes.draw do

  # ------------------------------------------ Robots

  get 'robots.:format' => 'robots#show'

  # ------------------------------------------ API

  namespace :api do
    namespace :v1 do
      resources :forms, :only => [:create]
      get 'database/dump' => 'database#dump', :as => :dump_db
    end
  end
  get 'api/*path' => 'api#missing', :as => :api_missing

  # ------------------------------------------ App Admin

  namespace :admin do
    get 'facebook/auth' => 'facebook#auth', :as => :facebook_auth
  end

  # ------------------------------------------ Devise

  devise_for :users, :skip => [:sessions, :registrations]
  devise_scope :user do
    get '/login' => 'devise/sessions#new', :as => :new_user_session
    post '/login' => 'devise/sessions#create', :as => :user_session
    get '/logout' => 'devise/sessions#destroy', :as => :destroy_user_session
  end

  # ------------------------------------------ Builder

  namespace :builder, :path => '' do
    resources :sites, :param => :slug do

      # Site Actions
      post 'pull' => 'sites#pull', :as => :pull
      post 'import' => 'sites#import', :as => :import
      post 'backup' => 'sites#backup', :as => :backup
      post 'sync' => 'sites#sync', :as => :sync
      post 'symlink' => 'sites#symlink', :as => :symlink

      # Pages
      resources :pages, :param => :slug do
        get 'settings/:slug' => 'pages#edit', :as => :settings
        get 'edit/:editor' => 'pages/editor#edit', :as => :editor
        patch 'edit/:editor' => 'pages/editor#parse', :as => :parser
        get 'help' => 'pages#help', :as => :help
        post 'publish' => 'pages#publish', :as => :publish
        post 'unpublish' => 'pages#unpublish', :as => :unpublish
      end

      # Templates
      resources :templates, :param => :slug, :path_names => { 
        :edit => :settings } do
        resources :template_fields, :path => :fields, 
          :controller => 'templates/fields', :param => :slug
        resources :template_groups, :path => :groups, 
          :controller => 'templates/groups', :param => :slug
        resources :pages, :controller => 'templates/template_pages', 
          :param => :slug, :only => [:index]
      end

      # Forms
      resources :forms, :param => :slug do
        resources :submissions, :param => :idx, :only => [:show]
      end

      # Files
      resources :documents, :path => :library, :param => :idx, 
        :except => [:show] do
          get 'crop' => 'documents/croppings#edit', :as => :cropper 
          patch 'crop' => 'documents/croppings#update', :as => :crop
      end

      # Users
      resources :users, :except => [:show]
    end
  end

  # ------------------------------------------ Viewer

  scope 'preview' do
    get '/' => 'previewer#dashboard', :as => :preview_dashboard
    scope ':site_slug' do
      get '/' => 'previewer#home', :as => :preview_home
      get '/*page_path' => 'previewer#show', :as => :preview_page
    end
  end

  # ------------------------------------------ Domains

  if ActiveRecord::Base.connection.table_exists?('sites')

    Site.all.each do |site|
      unless site.url.nil?
        constraints DomainConstraint.new(site.url) do
          get(
            '/' => 'viewer/pages#home', 
            :as => :"#{site.slug}_home"
          )
          get(
            '/*page_path' => 'viewer/pages#show', 
            :as => :"#{site.slug}_page"
          )
        end
        if site.respond_to?(:secondary_urls)
          site.redirect_domains.each do |domain|
            constraints DomainConstraint.new(domain) do
              get '/' => redirect("http://#{site.url}")
              get '/*page_path', :to => redirect { |params, request|
                "http://#{site.url}/#{params[:page_path]}"
              }
            end
          end
        end
      end
    end

  end

  # ------------------------------------------ Home Page

  root :to => 'builder#home'

end
