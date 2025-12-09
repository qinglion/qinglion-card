class Organization < ApplicationRecord
  belongs_to :admin_user, class_name: 'User', foreign_key: 'admin_user_id'
  has_many :profiles, dependent: :nullify
  has_one_attached :logo
  has_one_attached :background_image

  validates :name, presence: true
  validates :invite_token, uniqueness: true, allow_blank: true

  before_create :generate_invite_token

  # Status constants for profiles
  PROFILE_STATUSES = %w[pending approved rejected].freeze

  def approved_profiles
    profiles.where(status: 'approved')
  end

  def pending_profiles
    profiles.where(status: 'pending')
  end

  def is_admin?(user)
    admin_user_id == user&.id
  end

  private

  def generate_invite_token
    self.invite_token ||= SecureRandom.urlsafe_base64(32)
  end
end
