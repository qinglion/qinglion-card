class CreateOrganizations < ActiveRecord::Migration[7.2]
  def change
    create_table :organizations do |t|
      t.string :name, null: false
      t.text :description
      t.integer :admin_user_id
      t.string :invite_token

      t.timestamps
    end

    add_index :organizations, :admin_user_id
    add_index :organizations, :invite_token, unique: true
  end
end
