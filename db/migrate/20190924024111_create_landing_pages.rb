class CreateLandingPages < ActiveRecord::Migration[5.2]
  def change
    create_table :landing_pages do |t|
    	t.integer :campaign_id
    	t.string :splash
    	t.string :title
    	t.string :headline
    	t.string :pic_one
    	t.string :text_one
    	t.string :pic_two
    	t.string :text_two
    	t.string :pic_three
    	t.string :text_three

      t.timestamps
    end
  end
end
