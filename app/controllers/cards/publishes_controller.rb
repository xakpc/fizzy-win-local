class Cards::PublishesController < ApplicationController
  include CardScoped

  def create
    @card.publish

    redirect_to add_another_param? ? @collection.cards.create! : @card
  end

  private
    def add_another_param?
      params[:creation_type] == "add_another"
    end
end
