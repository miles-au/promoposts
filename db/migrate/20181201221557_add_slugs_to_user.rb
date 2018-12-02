class AddSlugsToUser < ActiveRecord::Migration[5.2]
  def change
  	add_column :users, :slug, :string

  	reversible do |dir|
	    dir.up { User.update_all('slug = id') }
	  end
  end
end
