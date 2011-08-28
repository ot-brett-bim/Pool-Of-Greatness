class Userstat
  attr_reader :name, :won, :lost, :tied, :win_percentage

  def self.find_by_season(season)
    users = User.joins(:pickem_week_entries => :pickem_week).where(:pickem_weeks => {:season => season})
    @userstats = []
    users.each do |user|
      won = lost = tied = 0
      user.pickem_week_entries.each do |entry|
        won += entry.pickem_entry_result.won
        lost += entry.pickem_entry_result.lost
        tied += entry.pickem_entry_result.tied
      end
      @userstats << new(user.name, won, lost, tied, user.pickem_week_entries.count)
    end

    @userstats.sort_by{ |obj| obj.win_percentage }.reverse
  end

  def initialize(name, won, lost, tied, weeks_played)
    @name = name
    @won = won
    @lost = lost
    @tied = tied
    @weeks_played = weeks_played
    @win_percentage = ((won.to_f / (won+lost+tied)) * 100).round(2)
  end
end
