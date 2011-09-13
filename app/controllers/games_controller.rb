class GamesController < ApplicationController
  before_filter :login_required
  before_filter :admin_required

  respond_to :html, :xml

  def index
    @title = "All Games"
  end

  def find
    @title = "Games Found"
    @games = Game.where("gamedate between ? AND ?", params[:begin_date], params[:end_date])
    logger.debug "Found #{@games.count} games"
    respond_with(@games)
  end

  def update_individual
    @games = Game.update(params[:games].keys, params[:games].values).reject { |g| g.errors.empty?}
    flash[:notice] = "Games updated"

    # TODO this needs to only happen for pickem pools. 
    if params[:scoregames]
      pools = PickemPool.all
      pools.each do |pool|
        week = PickemWeek.get_current_week(pool.id)
        week.score
        week.update_accounting
        @season = pool.pickem_rules.where("config_key = ?", "current_season").first
        @week = pool.pickem_rules.where("config_key = ?", "current_week").first
        pool.pickem_weeks.create!(:season => @season.config_value,
                                  :week => @week.config_value, 
                                  :deadline => week.deadline + 7)
      end
      
    end 

    
    redirect_to user_path(current_user)
  end

  def new
    @title = "Create a new game"
    @game = Game.new
  end

  def create
    if params[:game][:type] == 'Ncaagame'
      @game = Ncaagame.new(params[:game])
    else
      @game = Nflgame.new(params[:game])
    end
     
    if @game.save
      redirect_to games_path, :notice => "Game(s) created"
    else
      render :action => 'new'
    end

  end

  def edit
    @game = Game.find(params[:id]) 
  end

  def update
    @game = Game.find(params[:id])
    if @game.update_attributes(params[:game])
      flash[:success] = "Game updated"
      redirect_to @game
    else
      @title = "Edit game"
      render 'edit'
    end
     
  end

  def show
    @game = Game.find(params[:id]) 
  end
  
  private
    def admin_required
      redirect_to user_path(current_user) unless current_user.admin?
    end
end
