class ResultSerializer < ActiveModel::Serializer
  attributes :id, :mode, :hero, :hero_deck, :opponent, :opponent_deck,
    :coin, :result, :duration, :note, :added, :card_history

  attribute :arena_id, if: -> (r) { r.object.arena? }
  attribute :rank, if: -> (r) { r.object.ranked? }
  attribute :legend, if: -> (r) { r.object.ranked? }

  def card_history
    object.card_history_list.collect do |it|
      it.merge(card: CARDS[it[:card_id]].to_h)
    end
  end

  def hero
    object.hero.name
  end

  def hero_deck
    object.deck.try(:name)
  end

  def opponent
    object.opponent.name
  end

  def opponent_deck
    object.opponent_deck.try(:name)
  end
end
