class Topic < ApplicationRecord
	has_many :scheduled_posts
	has_many :subscribed_users, class_name:  "TopicRelationship",
                                  foreign_key: "topic_id"
	has_many :users, through: :subscribed_users
end
