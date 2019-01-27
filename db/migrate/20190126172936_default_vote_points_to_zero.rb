class DefaultVotePointsToZero < ActiveRecord::Migration[5.2]
  def change
  	change_column :votes, :points, :integer, :default => "Doe"
  end
end
