require "active_job/continuable"

class Event::WebhookDispatchJob < ApplicationJob
  include ActiveJob::Continuable

  queue_as :webhooks

  def perform(event)
    step :dispatch do |step|
      Webhook.triggered_by(event).find_each(start: step.cursor) do |webhook|
        webhook.trigger(event)
        step.advance! from: webhook.id
      end
    end
  end
end
