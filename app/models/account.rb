#
# Custom validator for currency type
class CurrencyValidator < ActiveModel::Validator
  CURRENCY_CODES = ["UYU","USD","EUR"]

  def validate(record)
    unless CURRENCY_CODES.include? record.currency
      record.errors.add :base, "Invalid currency"
    end
  end
end
    
class Account < ApplicationRecord 
  belongs_to :user
  has_many :transactions_sent,
            class_name: "Transaction",
            foreign_key: "account_from_id",
            dependent: :destroy
  has_many :transactions_received,
            class_name: "Transaction",
            foreign_key: "account_to_id",
            dependent: :destroy
    
  validates :balance, numericality: { greater_than_or_equal_to: 0 }
  validates_with CurrencyValidator

  # Account balances are rounded to two decimals

  def deposit(amount)
    self.balance = (self.balance + amount).round(2)
    self.save!
  end

  def withdraw(amount, account_to)
    if (account_to.user_id != self.user_id)
      # Apply 1% commission when transfering to an account the transfering user does not own
      self.balance = (self.balance - amount * 1.01).round(2)
    else
      self.balance = (self.balance - amount).round(2)
    end
    self.save!
  end
end
