class TransactionController < ApplicationController
  require 'net/http'

  before_action :logged_in_user # Defined in ApplicationController
  before_action :verify_logged_in

  # GET /transactions
  # Returns an array of transactions queried by (for logged in user):
  # @params source_account_id: integer
  # @params from: ISO date string
  # @params to:   ISO date string
  def get_transactions
    transactions = Transaction.find_by_account_and_timeframe_for_user({
      account_from_id: transaction_params[:source_account_id],
      from_date: transaction_params[:from],
      to_date: transaction_params[:to],
      user_id: @user.id
    })

    render json: transactions, status: :ok
  end

  # POST /transfer
  def create_transaction
    amount      = transfer_params['amount']
    description = transfer_params['description']
    date        = transfer_params['date']

    # Check if any of the parameters are missing
    return if check_missing_transaction_params(transfer_params)
    
    # Check if either account does not exist
    return unless @account_from = check_existing_account(transfer_params['account_from'])
    return unless @account_to = check_existing_account(transfer_params['account_to'])

    # Check if source account belongs to logged in user
    return unless check_account_from_belongs_to_user
        
    # Check if transfering to same account
    return if check_transfer_to_same_account

    #
    #
    # Execute transaction
    transaction = Transaction.execute(
      account_to: @account_to,
      account_from: @account_from,
      amount: amount.round(2),
      description: description,
      date: date
    )

    if transaction 
      render json: transaction, status: :ok
    else
      render json: { error: "Transaction failed to execute" }, 
                status: :unprocessable_entity
    end
  end

  #
  #
  #  
  
  private
    def transaction_params
      params.permit(:source_account_id, :from, :to)
    end

    def transfer_params
      params.permit(:account_from, 
                    :account_to, 
                    :amount,
                    :description,
                    :date)
    end
    
    # Check any if params in payload for transaction creation are missing
    def check_missing_transaction_params(params)
      unless present_transaction_params(params)
        render :json => { error: "Missing parameters in request body" }, 
                status: :unprocessable_entity
        return true
      end
      false
    end

    def present_transaction_params(params)
      return (params['account_from'].present? && params['account_to'].present? &&
              params['amount'].present? && params['description'].present? && params['date'].present?)
    end

    # Check if accounts exist
    # Returns fetched account if exists
    def check_existing_account(account_id)
      account = Account.find_by_id(account_id)
      unless account
        render json: { error: "Account does not exist" }, 
                status: :unprocessable_entity and return nil
      end
      account
    end

    # Check if account belongs to logged in user
    def check_account_from_belongs_to_user
      unless @account_from.user.id == @user.id
        render json: { error: "You can only make transactions from personal accounts" }, 
                status: :unprocessable_entity and return false
      end
      true
    end

    # Check if source and target account are the same
    def check_transfer_to_same_account
      if @account_from.id == @account_to.id
        render json: { error: "Cannot transfer to the same account" }, 
                status: :unprocessable_entity and return true
      end
      false
    end

    # Verifies if there is a logged in user
    # @user is fetched in before_action logged_in_user
    def verify_logged_in
      unless @user
        render json: { error: "Please log in to see your transactions" },
                   status: :unauthorized and return
      end
    end
end
