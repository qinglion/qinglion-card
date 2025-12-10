class Organization < ApplicationRecord
  belongs_to :admin_user, class_name: 'User', foreign_key: 'admin_user_id'
  has_many :profiles, dependent: :nullify
  has_one_attached :logo
  has_one_attached :background_image

  validates :name, presence: true
  validates :invite_token, uniqueness: true, allow_blank: true

  before_create :generate_invite_token
  after_save :add_admin_to_members, if: :saved_change_to_admin_user_id?

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

  def add_admin_to_members
    return unless admin_user_id.present?
    
    # Find or create profile for admin user
    admin_profile = admin_user.profile
    return unless admin_profile
    
    # Add admin to organization as approved member
    admin_profile.update(
      organization_id: id,
      status: 'approved'
    )
  end
end
