class User < ApplicationRecord
  include BCrypt

  has_many :accounts, dependent: :destroy

  attr_accessor :password

  PASSWORD_FORMAT = /\A
    (?=.*\d)           # Must contain a digit
    (?=.*[a-z])        # Must contain a lower case character
    (?=.*[A-Z])        # Must contain an upper case character
    (?=.*[[:^alnum:]]) # Must contain a symbol
  /x
  validates :password, presence: true, 
                       length: { minimum: 8 }, 
                       format: { with: PASSWORD_FORMAT }

  after_validation :hash_password, on: :create

  def hash_password
    self.password_hash = Password.create(self.password)
  end
end
