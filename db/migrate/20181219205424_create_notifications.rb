class CreateNotifications < ActiveRecord::Migration[5.2]
  def change
    create_table :notifications do |t|
      t.string :user_id
      t.string :message
      t.string :url

      t.timestamps
    end
  end
end
