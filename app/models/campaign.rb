class Campaign < ApplicationRecord
  has_many :microposts, dependent: :destroy
  belongs_to :user
  has_one :landing_page, dependent: :destroy
  validates :name, presence: true, length: { maximum: 75 }
  validates :content, presence: true, length: { maximum: 400 }
  accepts_nested_attributes_for :microposts
  accepts_nested_attributes_for :landing_page
end
