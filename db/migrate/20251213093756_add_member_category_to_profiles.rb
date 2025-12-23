class AddMemberCategoryToProfiles < ActiveRecord::Migration[7.2]
  def change
    add_column :profiles, :member_category, :string

  end
end
