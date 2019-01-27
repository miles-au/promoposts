class AddTopCommentToMicropost < ActiveRecord::Migration[5.2]
  def change
  	add_column :microposts, :top_comment, :integer
  end
end
