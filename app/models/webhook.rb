class Webhook < ApplicationRecord
  PERMITTED_SCHEMES = %w[ http https ].freeze
  PERMITTED_ACTIONS = %w[
    card_assigned
    card_boosted
    card_closed
    card_collection_changed
    card_created
    card_popped
    card_published
    card_reopened
    card_staged
    card_title_changed
    card_unassigned
    card_unstaged
    comment_created
  ].freeze

  encrypts :signing_secret
  has_secure_token :signing_secret

  has_many :deliveries, dependent: :delete_all

  serialize :subscribed_actions, type: Array, coder: JSON

  scope :ordered, -> { order(name: :asc, id: :desc) }
  scope :active, -> { where(active: true) }
  scope :triggered_by_action, ->(action) { where("subscribed_actions LIKE ?", "%\"#{action}\"%") }
  scope :triggered_by, ->(event) { active.triggered_by_action(event.action) }

  # normalizes :subscribed_actions, with: ->(value) { Array(value).map(&:to_s).map(&:strip).reject(&:blank?).uniq & PERMITTED_ACTIONS }

  validates :name, presence: true
  validates :subscribed_actions, presence: true

  validate :validate_url

  def deactivate
    update_columns active: false
  end

  def trigger(event)
    deliveries.create!(event: event).deliver_later
  end

  private
    def validate_url
      uri = URI.parse(url.presence)

      if PERMITTED_SCHEMES.exclude?(uri.scheme)
        errors.add :url, "must use #{PERMITTED_SCHEMES.to_choice_sentence}"
      end
    rescue URI::InvalidURIError
      errors.add :url, "not a URL"
    end
end
