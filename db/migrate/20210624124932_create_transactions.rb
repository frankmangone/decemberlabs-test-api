class CreateTransactions < ActiveRecord::Migration[6.0]
  def change
    create_table :transactions do |t|
      t.decimal :amount
      t.string :description
      t.references :account_from, null: false, foreign_key: { to_table: :accounts }, index: true
      t.references :account_to,   null: false, foreign_key: { to_table: :accounts }, index: true

      t.timestamps
    end
  end
end
