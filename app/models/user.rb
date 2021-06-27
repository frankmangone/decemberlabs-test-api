class User < ApplicationRecord
  has_secure_password
  has_many :accounts, dependent: :destroy

  PASSWORD_FORMAT = /\A
    (?=.*\d)           # Must contain a digit
    (?=.*[a-z])        # Must contain a lower case character
    (?=.*[A-Z])        # Must contain an upper case character
    (?=.*[[:^alnum:]]) # Must contain a symbol
  /x
  validates :password, presence: true, 
                       length: { minimum: 8 }, 
                       format: { with: PASSWORD_FORMAT }

end
