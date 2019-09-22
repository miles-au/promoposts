class AddOnScheduleToAccounts < ActiveRecord::Migration[5.2]
  def change
  	add_column :accounts, :on_schedule, :boolean, default: false
  end
end
