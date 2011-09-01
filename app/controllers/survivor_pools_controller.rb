class SurvivorPoolsController < ApplicationController
  before_filter :login_required 

  def index
  end
  
  def show
    @pool = SurvivorPool.find(params[:id])
    @title = "#{@pool.name} Home"
    @current_week = @pool.current_week
    @current_pick = current_user.survivor_entries.where(:week => @current_week, :season => "2011-2012").first
  end

  def viewpicksheet
    @title = "Picksheet"
    @pool = SurvivorPool.find(params[:id])
    @games = @pool.get_weekly_games
    @entry = SurvivorEntry.where(:user_id => current_user.id, :week => @games[0].week, :season => @games[0].season).first
    if @entry.nil?
      @entry = SurvivorEntry.new
    end

  end

  def makepick
    @pool = SurvivorPool.find(params[:id])
    team = Team.find(params[:teamid]) 
    @games = @pool.get_weekly_games
    game = @games.where("away_team_id = ? OR home_team_id = ?", team.id, team.id).first

    @entry = SurvivorEntry.where(:user_id => current_user.id, :week => game.week, :season => game.season).first
    if @entry.nil?
      current_user.survivor_entries.create!(:game => game, :team => team)
    else
      @entry.update_attributes(:game => game, :team => team)
      @entry.save
    end
    flash[:notice] = "Week #{game.week} successfully made"

    redirect_to survivor_pool_path(@pool) 
  end

  def standings
    @pool = SurvivorPool.find(params[:id])
    @title = "Pool Standings"
    @current_week = @pool.current_week 

    if !@pool.show_week?
      @current_week -= 1
    end

    # TODO another season fix
    @users = User.joins(:survivor_entries).where("survivor_entries.season = ? and survivor_entries.week = ?",  "2011-2012", @current_week).all

    if @users.count == 0
      flash[:notice] = "No standings until after the week 1 deadline"
    end
  end
end
