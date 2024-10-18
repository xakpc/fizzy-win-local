class BubblesController < ApplicationController
  include BucketScoped

  before_action :set_bubble, only: %i[ show edit update ]
  before_action :clear_assignees, only: :index
  before_action :set_view, :set_tag_filters, :set_assignee_filters, only: :index

  def index
    @bubbles = @bucket.bubbles
    @bubbles = @bubbles.ordered_by(params[:order_by] || Bubble.default_order_by)
    @bubbles = @bubbles.with_status(params[:status] || Bubble.default_status)
    @bubbles = @bubbles.tagged_with(@tag_filters) if @tag_filters
    @bubbles = @bubbles.assigned_to(@assignee_filters) if @assignee_filters
    @bubbles = @bubbles.mentioning(params[:term]) if params[:term]
  end

  def new
    @bubble = @bucket.bubbles.build
  end

  def create
    @bubble = @bucket.bubbles.create!
    redirect_to bucket_bubble_url(@bucket, @bubble)
  end

  def show
  end

  def edit
  end

  def update
    @bubble.update! bubble_params
    redirect_to bucket_bubble_url(@bucket, @bubble)
  end

  private
    def set_bubble
      @bubble = @bucket.bubbles.find params[:id]
    end

    def bubble_params
      params.require(:bubble).permit(:title, :color, :due_on, :image, tag_ids: [])
    end

    def clear_assignees
      params[:assignee_ids] = nil if helpers.unassigned_filter_activated?
    end

    def set_view
      @view = @bucket.views.find_by_id(params[:view_id]) if params[:view_id]
      @view ||= @bucket.views.find_by(creator: Current.user, filters: helpers.bubble_filter_params.to_h)
      params[:view_id] = @view&.id
    end

    def set_tag_filters
      if params[:tag_ids]
        @tag_filters = Current.account.tags.where id: params[:tag_ids]
      end
    end

    def set_assignee_filters
      if params[:assignee_ids]
        @assignee_filters = Current.account.users.where id: params[:assignee_ids]
      end
    end
end
