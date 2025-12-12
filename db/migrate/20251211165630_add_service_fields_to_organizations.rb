class AddServiceFieldsToOrganizations < ActiveRecord::Migration[7.2]
  def change
    add_column :organizations, :service_advantage_1_title, :string
    add_column :organizations, :service_advantage_1_description, :text
    add_column :organizations, :service_advantage_2_title, :string
    add_column :organizations, :service_advantage_2_description, :text
    add_column :organizations, :service_advantage_3_title, :string
    add_column :organizations, :service_advantage_3_description, :text
    add_column :organizations, :service_process_1_title, :string
    add_column :organizations, :service_process_1_description, :text
    add_column :organizations, :service_process_2_title, :string
    add_column :organizations, :service_process_2_description, :text
    add_column :organizations, :service_process_3_title, :string
    add_column :organizations, :service_process_3_description, :text
    add_column :organizations, :service_process_4_title, :string
    add_column :organizations, :service_process_4_description, :text
    add_column :organizations, :cta_title, :string
    add_column :organizations, :cta_description, :text

  end
end
