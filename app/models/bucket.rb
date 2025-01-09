class Bucket < ApplicationRecord
  include Accessible, Broadcastable, Filterable

  belongs_to :account
  belongs_to :creator, class_name: "User", default: -> { Current.user }

  has_many :bubbles, dependent: :destroy
  has_many :tags, -> { distinct }, through: :bubbles

  validates_presence_of :name
end
