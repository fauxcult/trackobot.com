class Stats::DecksController < ApplicationController
  respond_to :json, :html

  TIME_RANGE_FILTERS = %w[last_24_hours last_3_days current_month]

  def index
    @stats = {
      overall: {
      },
      decks: {
        vs: {},
        as: {}
      }
    }

    if params[:mode].present? && Result.modes.has_key?(params[:mode].to_sym)
      @mode = params[:mode].to_sym
    end

    if params[:time_range].present? && TIME_RANGE_FILTERS.include?(params[:time_range])
      @time_range = params[:time_range].to_sym
    end

    if params[:as_deck].present?
      @as_deck = current_user.decks.find_by_id(params[:as_deck])
    end
    if params[:vs_deck].present?
      @vs_deck = current_user.decks.find_by_id(params[:vs_deck])
    end

    user_results = current_user.results
    user_results = user_results.where('created_at >= ?', min_date_for_time_range(@time_range)) if @time_range
    user_results = user_results.where(mode: Result.modes[@mode]) if @mode

    @stats[:decks][:as] = group_results_by(user_results, current_user.decks, @as_deck, :deck_id, :opponent_deck_id, @vs_deck.try(:id))
    @stats[:decks][:vs] = group_results_by(user_results, current_user.decks, @vs_deck, :opponent_deck_id, :deck_id, @as_deck.try(:id))

    @stats[:overall][:wins] = user_results.wins.count
    @stats[:overall][:losses] = user_results.losses.count

    respond_to do |format|
      format.html
      format.json do
        render json: {stats: @stats}
      end
    end
  end

  private

  def min_date_for_time_range(time_range)
    case time_range
    when :last_24_hours
      24.hours.ago
    when :last_3_days
      3.days.ago
    when :current_month
      Date.today.beginning_of_month
    end
  end

  def win_rate(wins, losses)
    total = wins + losses
    return 0 if total == 0
    return wins.to_f / total
  end

  def group_results_by(results, all_group_elements, group_element, group_id_key, filter_key, filter_value = nil)
    Hash[
      [ group_element || all_group_elements ].flatten.collect do |group|
        group_results = results.where(group_id_key => group.id)
        if filter_value
          group_results = group_results.where(filter_key => filter_value)
        end
        [ group, { total: group_results.count, wins: group_results.wins.count, losses: group_results.losses.count } ]
      end.sort_by { |_, stats| [ win_rate(stats[:wins], stats[:losses]), stats[:total] ] }.reverse # sort desc
    ]
  end
end