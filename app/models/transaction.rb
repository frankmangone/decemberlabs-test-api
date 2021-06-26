class Transaction < ApplicationRecord
  belongs_to :account_from, class_name: :Account
  belongs_to :account_to,   class_name: :Account

  validates :account_from, presence: true
  validates :account_to, presence: true

  validates :amount, presence: true, 
                     numericality: { greater_than: 0 }

  validates :description, presence: true

  # Query for /transactions route
  def self.find_by_account_and_timeframe_for_user(query_params)

    #
    # query_params[:user_id] is assumed not to be nil
    transactions = Transaction.where(nil)
    
    # Query by from_date
    transactions = transactions.where(
      'date > ?', DateTime.iso8601(query_params[:from_date])
      ) if query_params[:from_date].present?
    
    # Query by to_date
    transactions = transactions.where(
      'date < ?', DateTime.iso8601(query_params[:to_date])
      ) if query_params[:to_date].present?

    # Query by account_from_id
    transactions = transactions.where(
      account_from_id: query_params[:account_from_id]
    ) if query_params[:account_from_id].present?
  
    # Query by account (both from and to) belonging to user
    transactions = transactions
      .joins('INNER JOIN accounts as account_to ON "account_to"."id" = "transactions"."account_to_id"')
    if query_params[:account_from_id].present?
      # If source account is present, do not query by account_from belonging to user
      transactions = transactions.where(account_to: { user_id: query_params[:user_id] })
    else
      transactions = transactions
        .joins('INNER JOIN accounts as account_from ON "account_from"."id" = "transactions"."account_from_id"')
      transactions = transactions.where(account_to: { user_id: query_params[:user_id] })
                            .or(transactions.where(account_from: { user_id: query_params[:user_id] }))
    end

    return transactions
  end

  # Execute transaction, both creating the record
  # and changing the balances of the corresponding accounts
  def self.execute(params)

    # Initialize transaction record
    transaction = Transaction.new({
      account_to:   params[:account_to],
      account_from: params[:account_from],
      amount:       params[:amount].round(2),
      description:  params[:description],
      date:         params[:date]
    })

    # Calculate corrected amount
    corrected_amount = calculate_corrected_amount(
      params[:account_from],
      params[:account_to],
      params[:amount]
    )

    # Execute atomic transaction
    # This is done to ensure simultaneos success of the 3 operations
    begin
      ActiveRecord::Base.transaction do
        params[:account_from].withdraw(params[:amount], params[:account_to])
        params[:account_to].deposit(corrected_amount)
        transaction.save!
      end
    rescue StandardError => e
      # TODO: Return validation error
      return nil
    end

    return transaction
  end

  private
    #
    # Calculate amount given both a source and target account
    # Assumes the currency in each account is valid in the fixer.io response
    def self.calculate_corrected_amount(account_from, account_to, original_amount)
      #
      # Get exchange rates from Fixer.io API
      rates = get_cached_exchange_rates
      
      source_rate = get_rate(account_from.currency, rates)
      target_rate = get_rate(account_to.currency,   rates)

      # Converts from source to target currency
      original_amount / source_rate * target_rate
    end

    #
    # Get exchange rates from cache if they exist; if not, make request to fixer.io
    def self.get_cached_exchange_rates
      expires_in_seconds = Time.now.end_of_day - Time.now
      Rails.cache.fetch(ENV['EXCHANGE_RATES_CACHE_KEY'], expires_in: expires_in_seconds) do
        url = URI.parse("http://data.fixer.io/api/latest?access_key=#{ENV['FIXER_API_KEY']}")
        req = Net::HTTP::Get.new(url.to_s)
        res = Net::HTTP.start(url.host, url.port) {|http|
          http.request(req)
        }
        res = JSON.parse(res.body)
        return { 'EUR': 1, 'USD': res['rates']['USD'], 'UYU': res['rates']['UYU'] }
      end
    end

    #
    # Get rate corresponding to a currency
    def self.get_rate(currency, rates)
      if currency == 'EUR'
        return 1
      elsif currency == 'USD'
        return rates[:USD]
      elsif currency == 'UYU'
        return rates[:UYU]
      end
      #
      return nil
    end
end
