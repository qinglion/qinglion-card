class CreateRenewals < ActiveRecord::Migration[7.2]
  def change
    create_table :renewals do |t|
      t.references :profile, null: false, foreign_key: true
      t.date :payment_date, null: false
      t.decimal :amount, precision: 10, scale: 2, null: false
      t.text :notes

      t.timestamps
    end

    add_index :renewals, [:profile_id, :payment_date]
  end
end
