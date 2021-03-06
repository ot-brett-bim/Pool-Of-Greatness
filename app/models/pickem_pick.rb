class PickemPick < ActiveRecord::Base
  attr_accessible :team, :game, :team_id, :game_id

  belongs_to :game
  belongs_to :team
  belongs_to :pickem_week_entry

  default_scope :joins => :game, :order => 'games.gamedate, games.id'

  def picked_favorite?
    game.favorite.teamname == team.teamname
  end

  def picked_underdog?
    game.underdog.teamname == team.teamname
  end
end
