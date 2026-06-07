class User < ApplicationRecord
  has_many :books, dependent: :destroy
  has_many :reviews, dependent: :destroy
  has_many :reviewed_books, through: :reviews, source: :book
  validates :email, presence: true, uniqueness: true
  before_save { self.email = email.downcase }
  has_secure_password
end
