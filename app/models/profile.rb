class Profile < ApplicationRecord
  extend FriendlyId
  friendly_id :slug_candidates, use: :slugged
  
  # Member category constants
  MEMBER_CATEGORIES = [
    '终身卡',
    '年度会员',
    '课次会员',
    '预科',
    '读书会'
  ].freeze
  
  def slug_candidates
    [
      :email_username,
      [:email_username, :id]
    ]
  end
  
  def email_username
    return nil if email.blank?
    email.split('@').first
  end

  belongs_to :user
  belongs_to :organization, optional: true
  has_many :case_studies, dependent: :destroy
  has_many :honors, dependent: :destroy
  has_many :chat_sessions, dependent: :destroy
  has_many :chat_messages, through: :chat_sessions
  
  has_one_attached :avatar
  has_one_attached :background_image

  serialize :specializations, coder: JSON

  validates :full_name, presence: true
  validates :title, presence: true
  validates :slug, uniqueness: true, allow_blank: true
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }, allow_blank: true
  validates :phone, format: { with: /\A[0-9\-\(\)\+\s]+\z/ }, allow_blank: true
  validates :status, inclusion: { in: %w[pending approved rejected] }
  validates :member_category, inclusion: { in: MEMBER_CATEGORIES }, allow_blank: true

  # Scopes
  scope :approved, -> { where(status: 'approved') }
  scope :pending, -> { where(status: 'pending') }
  scope :rejected, -> { where(status: 'rejected') }

  # Default stats structure
  after_initialize :set_default_stats, if: :new_record?
  after_initialize :set_default_onboarding_data, if: :new_record?

  def set_default_stats
    self.stats ||= {
      'years_experience' => 0,
      'cases_handled' => 0,
      'clients_served' => 0,
      'success_rate' => 0
    }
  end

  def specializations_array
    return [] unless specializations.is_a?(Array)
    # 过滤空值和空字符串，确保只返回有效关键词
    specializations.compact.map(&:strip).reject(&:blank?)
  end

  # Onboarding status methods
  def needs_onboarding?
    !onboarding_completed
  end

  def complete_onboarding!
    update(onboarding_completed: true, onboarding_step: 'completed')
  end

  def set_default_onboarding_data
    self.onboarding_data ||= {
      'intro' => nil,
      'specializations_text' => nil,
      'case_story' => nil,
      'brand_style' => nil,
      'contact_preferences' => nil
    }
  end

  # Organization status methods
  def pending?
    status == 'pending'
  end

  def approved?
    status == 'approved'
  end

  def rejected?
    status == 'rejected'
  end

  def approve!
    transaction do
      update!(status: 'approved')
      if user.present?
        token = user.generate_registration_token
        user.update!(activated: true)
        
        UserMailer.with(
          user: user, 
          token: token, 
          organization_name: organization&.name || 'Our Platform'
        ).approval_notification.deliver_later
      end
    end
  rescue ActiveRecord::RecordInvalid => e
    errors.add(:base, e.message)
    false
  end

  def reject!
    update(status: 'rejected')
  end
end
