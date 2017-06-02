Rails.application.routes.draw do
  resources :opml_uploaders
	# Tags
	get "/tags/clean", to: "tags#clean", as: "clean_tags"
	resources :tags

	# Entries
	resources :entries

	# Sources
	get "/sources/update_all", to: "sources#update_all", as: "update_sources"
	resources :sources
	get "/sources/:id/entries", to: "sources#show_entries", as: "source_entries"
	get "/sources/:id/update_entries", to: "sources#update_entries", as: "update_source"

	# API
	get "/api/all", to: "api#show", as: "api_all"

	# Application
	get "/sidebars", to: "application#sidebars", as: "sidebars"

	# The priority is based upon order of creation: first created -> highest priority.
	# See how all your routes lay out with "rake routes".

	# You can have the root of your site routed with "root"
	root 'entries#index'

	# Example of regular route:
	#   get 'products/:id' => 'catalog#view'

	# Example of named route that can be invoked with purchase_url(id: product.id)
	#   get 'products/:id/purchase' => 'catalog#purchase', as: :purchase

	# Example resource route (maps HTTP verbs to controller actions automatically):
	#   resources :products

	# Example resource route with options:
	#   resources :products do
	#     member do
	#       get 'short'
	#       post 'toggle'
	#     end
	#
	#     collection do
	#       get 'sold'
	#     end
	#   end

	# Example resource route with sub-resources:
	#   resources :products do
	#     resources :comments, :sales
	#     resource :seller
	#   end

	# Example resource route with more complex sub-resources:
	#   resources :products do
	#     resources :comments
	#     resources :sales do
	#       get 'recent', on: :collection
	#     end
	#   end

	# Example resource route with concerns:
	#   concern :toggleable do
	#     post 'toggle'
	#   end
	#   resources :posts, concerns: :toggleable
	#   resources :photos, concerns: :toggleable

	# Example resource route within a namespace:
	#   namespace :admin do
	#     # Directs /admin/products/* to Admin::ProductsController
	#     # (app/controllers/admin/products_controller.rb)
	#     resources :products
	#   end
end
