class Book < ApplicationRecord
  belongs_to :user
  has_many :reviews, dependent: :destroy
  validates :title, presence: true
  enum :status, { want_to_read: 0, reading: 1, finished: 2 }
end
