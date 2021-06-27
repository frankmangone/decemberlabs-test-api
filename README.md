## DecemberLabs API Test

# 1. Introduction
In order to start using this API in a development environment:
  1) Make sure to have a working installation of PostgreSQL
  2) Install gems:
  > $ bundle install
  3) Create and populate the database: 
  > $ rails db:create
  > 
  > $ rails db:migrate
  > 
  > $ rails db:seed

This will create 3 test Users (testing1, testing2, testing3), each of which have 2 Accounts.
The password for each user is 'Password.[i]', where `[i]` is the user number (for testing1, Password.1, and so on).

This API has two endpoints:
  - GET  /transactions : lists transactions for the logged in user.
  - POST /transfer : makes a transaction from a source account, to a target account.

Both of this endpoints require the user to be logged in. Although an authentication mechanism was not fully implemented, the endpoints expect to receive a JWT. To obtain this token, it is possible to produce one by going into the rails console, and running:
> $ rails c
> 
> ApplicationController.encode_token(user_id: [user_id])

Where `[user_id]` must be a valid id from the existen User records. The `[token]` must then be inserted into the request headers.

In order to make requests to the API, it's possible to use *cURL*. The following commands make the corresponding requests:

  /transactions: 
  > $ curl -H "Authorization: Bearer [token]" -X GET "http://localhost:3000/transactions?[params])"

  /transfer: 
  > $ curl -d '[body]' -i -H "Accept: application/json" -H "Content-Type: application/json" -H "Authorization: Bearer [token]" -X POST "http://localhost:3000/transfer/"

Both `[body]` and `[params]` will be defined later in this file.


# 2. Model
Three entities are used in this work: User, Account, and Transaction.
A User may have more than one account, and an Account may have many Transactions, connected both through account_to and account_from (since Transactions have both foreign keys).

An Account can access the sent Transactions through `account.transactions_sent`, and received transactions through `account.transactions_received`. The inverse relationship can also be accessed, using `transaction.account_from` and `transaction.account_to`.

The models have the following columns, in addition to `created_at` and `updated_at` timestamps:

# 2.1 User
 - `id` [integer] [indexed]
 - `username` [string]
 - `password_hash` [string]

# 2.2 Account
 - `id` [integer] [indexed]
 - `user_id` [integer]
 - `currency` [string]
 - `balance` [float]

# 2.3 Transaction
 - `id` [integer] [indexed]
 - `account_to_id` [integer] [indexed]
 - `account_from_id` [integer] [indexed]
 - `amount` [float]
 - `date` [timestamp] [indexed]
 - `description` [string]

The columns `date`, `account_to_id`, and `account_from_id`, are indexed because of the query requirements in the /transaction endpoint.


# 3. Endpoints

# 3.1 /transactions
Returns an array of Transactions.

This endpoint accepts the following parameters:
  - `from`: [dateISOstring]
  - `to`: [dateISOstring]
  - `source_account_id`: [id(integer)]

To generate the ISO strings, in the console, you can run:

> $ Time.now.utc.iso8601

Dates can be passed in many different formats; a possible *enhancement* for the future could be to accept and correctly parse different formats.

Parameters can be passed in the url as query params, as in the following example:
  "http://localhost:3000/transactions?from=2021-06-24T00:00:00.000Z&to=2021-06-26T00:00:00.000Z&source_account_id=1"

The endpoint also querys by accounts belonging to the logged in user, so only the Transactions whose account_from OR account_to belong to the current user will be shown.

# 3.2 /transfer
Creates a Transaction from a source account to a target account.
Returns the Transaction upon successful execution.

This endpoint expects the following entries in the request body:
  - `account_from`: [id(integer)]
  - `account_to`: [id(integer)]
  - `date`: [dateISOstring]
  - `amount`: [float]
  - `description`: [string]

These values are required for a successful transfer; if any are missing, the Transaction will fail to execute. An example header with this body would be:
  > $curl -d '{"account_from":1,"account_to":2,"amount":200,"description":"First transaction","date":"2021-06-25T19:40:20.450Z"}' (...)

Remember to add headers for the content type:
  `-H "Accept: application/json" -H "Content-Type: application/json"`

The following conditions are checked before fulfilling the Transaction:
  - No missing parameters in the request body.
  - Accounts must exist.
  - Source account must belong to existing user.
  - Transfer cannot have the same source and target account.
  - Source account must have enough funds.

Transfered amounts are rounded to the second decimal place.

The exchange rates are fetched from the fixer.io API. The results are *cached*, since the request is assumed to be expensive (and it really is slow!). The cache expires at the end of each day, so that exchange rates are always updated.

The Transaction save, withdraw from source account, and deposit into target account are executed as an atomic transaction, so that no imbalance exists as a final result (and money is neither created nor destroyed magically!).


# 4. Future work / Enhancements
  - Add more accepted currency codes. Right now, only EUR, USD, and UYU are accepted.
  - Add a minimum amount to transfer.
  - Abstract cache method to separate class for future reuse, with dynamic cache keys.
  - Add pagination to /transactions result.
  - Move business logic to interactors (ActiveInteractor) to create lean Models and Controllers.
  - Add better validation errors. In this example, they are treated very loosely, due to time constraints.
  - Implement user authentication.
  - Standarize response format.
  - Tests.
