class AddOrganizationToProfiles < ActiveRecord::Migration[7.2]
  def change
    add_column :profiles, :organization_id, :integer
    add_column :profiles, :status, :string, default: "pending"
    add_column :profiles, :department, :string

    add_index :profiles, :organization_id
    add_index :profiles, :status
  end
end
