class Campaign < ApplicationRecord
  has_many :microposts, dependent: :destroy
  belongs_to :user
  validates :name, presence: true, length: { maximum: 75 }
  accepts_nested_attributes_for :microposts
end
