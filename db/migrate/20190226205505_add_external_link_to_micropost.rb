class AddExternalLinkToMicropost < ActiveRecord::Migration[5.2]
  def change
  	add_column :microposts, :external_url, :string
  end
end
