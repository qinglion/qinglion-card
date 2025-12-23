class AddTestimonialsToProfiles < ActiveRecord::Migration[7.2]
  def change
    add_column :profiles, :testimonials, :text

  end
end
