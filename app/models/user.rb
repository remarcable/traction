class User < ApplicationRecord
  has_secure_password
  has_many :sessions, dependent: :destroy
  has_many :habits, dependent: :destroy

  normalizes :email_address, with: ->(e) { e.strip.downcase }

  validates :email_address, presence: true,
                          format: { with: URI::MailTo::EMAIL_REGEXP },
                          uniqueness: { case_sensitive: false }
  validates :password, length: { minimum: 6 }, if: -> { password.present? }
end
