json.partial! "cards/card", card: @card
json.steps @card.steps, partial: "steps/step", as: :step
