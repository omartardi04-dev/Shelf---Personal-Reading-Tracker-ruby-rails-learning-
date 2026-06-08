class Book < ApplicationRecord
  belongs_to :user
  has_many :reviews, dependent: :destroy
  validates :title, presence: true, uniqueness: true
  enum :status, { want_to_read: 0, reading: 1, finished: 2 }
  scope :recently_added, -> { order(created_at: :desc) }
  def as_json(options = {})
    super(except: :user_id)
  end
end
