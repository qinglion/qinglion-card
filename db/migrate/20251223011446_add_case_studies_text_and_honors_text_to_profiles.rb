class AddCaseStudiesTextAndHonorsTextToProfiles < ActiveRecord::Migration[7.2]
  def change
    add_column :profiles, :case_studies_text, :text
    add_column :profiles, :honors_text, :text

  end
end
