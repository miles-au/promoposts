class CreateTopicRelationships < ActiveRecord::Migration[5.2]
  def change
    create_table :topic_relationships do |t|
    	t.integer :user_id
    	t.integer :topic_id

      t.timestamps
    end
    add_index :topic_relationships, :user_id
    add_index :topic_relationships, :topic_id
  end
end
