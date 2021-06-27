# Create test users
user1 = User.create(username: 'testing1', password: 'Password.1', password_confirmation: 'Password.1')
user2 = User.create(username: 'testing2', password: 'Password.2', password_confirmation: 'Password.2')
user3 = User.create(username: 'testing3', password: 'Password.3', password_confirmation: 'Password.3')

account_list = [{ currency: 'UYU', balance: 1000, user_id: user1.id },
                { currency: 'USD', balance: 100,  user_id: user1.id },
                { currency: 'UYU', balance: 2000, user_id: user2.id },
                { currency: 'EUR', balance: 1000, user_id: user2.id },
                { currency: 'USD', balance: 5000, user_id: user3.id },
                { currency: 'EUR', balance: 0,    user_id: user3.id }]

# Create test accounts
account_list.each do |account|
  Account.create( 
    currency: account[:currency],            
    balance:  account[:balance],
    user_id:  account[:user_id]
  )
end
