class Renewal < ApplicationRecord
  belongs_to :profile

  validates :payment_date, presence: true
  validates :amount, presence: true, numericality: { greater_than: 0 }

  # Scopes
  scope :recent, -> { order(payment_date: :desc) }
  scope :by_profile, ->(profile_id) { where(profile_id: profile_id) }

  # Display formatted amount
  def formatted_amount
    "¥#{amount.to_f.round(2)}"
  end
end
