class AddOnboardingStageAndRemoveCategoryFromUser < ActiveRecord::Migration[5.2]
  def change
  	remove_column :users, :category
  	add_column :users, :onboarding_stage, :integer, default: 0
  end
end
