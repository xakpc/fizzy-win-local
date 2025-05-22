module UserTimelineScoped
  extend ActiveSupport::Concern

  included do
    include FilterScoped
  end

  def show
    @filter = Current.user.filters.new(creator_ids: [ @user.id ])
    @day_timeline = Current.user.timeline_for(Time.current, filter: @filter)
  end
end
