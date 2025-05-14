module Card::Engageable
  extend ActiveSupport::Concern

  STAGNATED_AFTER = 30.days
  AUTO_RECONSIDER_REMINDER_BEFORE = 7.days

  included do
    has_one :engagement, dependent: :destroy, class_name: "Card::Engagement"

    scope :considering, -> { published_or_drafted_by(Current.user).open.where.missing(:engagement) }
    scope :doing,       -> { published.open.joins(:engagement) }
    scope :stagnated,   -> { doing.where(last_active_at: ..STAGNATED_AFTER.ago) }

    scope :by_engagement_status, ->(status) do
      case status.to_s
      when "considering" then considering
      when "doing"       then doing.with_golden_first
      end
    end
  end

  class_methods do
    def auto_reconsider_all_stagnated
      stagnated.find_each(&:reconsider)
    end
  end

  def auto_reconsider_at
    last_active_at + STAGNATED_AFTER if last_active_at
  end

  def days_until_reconsider
    (auto_reconsider_at.to_date - Date.current).to_i if auto_reconsider_at
  end

  def doing?
    open? && published? && engagement.present?
  end

  def considering?
    open? && published? && engagement.blank?
  end

  def reconsidering_soon?
    doing? && Time.current >= auto_reconsider_at - AUTO_RECONSIDER_REMINDER_BEFORE
  end

  def engage
    unless doing?
      transaction do
        reopen
        create_engagement!
      end
    end
  end

  def reconsider
    transaction do
      reopen
      engagement&.destroy
      touch(:last_active_at)
    end
  end
end
