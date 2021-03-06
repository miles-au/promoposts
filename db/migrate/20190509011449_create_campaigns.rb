class CreateCampaigns < ActiveRecord::Migration[5.2]
  def change
    create_table :campaigns do |t|
      t.string :name
      t.references :user, foreign_key: true

      t.timestamps
    end
    add_index :campaigns, [:created_at]
  end
end
