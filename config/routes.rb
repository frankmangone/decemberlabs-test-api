Rails.application.routes.draw do
  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html

  get '/transactions', to: 'transaction#get_transactions'
  post '/transfer', to: 'transaction#create_transaction'
end
