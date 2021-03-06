class LeaderboardEntry
  attr_reader :player, :won, :lost, :left, :potential, :percentage
  
  def initialize(user)
    @player = user
    @won = 0
    @lost = 0
    @left = 0
  end

  def score_entry(season)
    @player.confidence_picks.joins(:bowl).where("bowls.season = '#{season}'").each do |pick|
      if(pick.bowl.winning_team.nil?)
        @left += pick.rank
      elsif(pick.team == pick.bowl.winning_team)
        @won += pick.rank
      else
        @lost += pick.rank
      end
    end

    @potential = @won + @left
    @percentage = ((@won.to_f/(@won + @lost)) * 100).round(2) unless (@won + @lost) == 0
  end

  def largest_left
    season = DbConfig.get_value_by_key("CurrentBowlSeason")
    rank = @player.confidence_picks.joins(:bowl).where("bowls.season = '#{season}' and bowls.favorite_score + bowls.underdog_score = 0").maximum("rank")
    pick = @player.confidence_picks.joins(:bowl).where("bowls.season = '#{season}' and rank = ?", rank).first
    
    if(pick.nil?)
      "None"
    else
      "#{pick.team.display_name} (#{pick.rank})"
    end
  end

  def second_largest_left
    season = DbConfig.get_value_by_key("CurrentBowlSeason")
    rank = @player.confidence_picks.joins(:bowl).where("bowls.season = '#{season}' and bowls.favorite_score + bowls.underdog_score = 0").maximum("rank")
    second = @player.confidence_picks.joins(:bowl).where("bowls.season = '#{season}' and bowls.favorite_score + bowls.underdog_score = 0 AND rank < ?", rank).maximum("rank")
    pick = @player.confidence_picks.joins(:bowl).where("bowls.season = '#{season}' and rank = ?", second).first

    if(pick.nil?)
      "None"
    else
      "#{pick.team.display_name} (#{pick.rank})"
    end
  end
end
