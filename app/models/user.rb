class User < ActiveRecord::Base
  # new columns need to be added here to be writable through mass assignment
  attr_accessible :username, :email, :password, :password_confirmation, :name, :lowered_username
  attr_accessor :password
  before_save :prepare_password, :lower_username
  
  validates_presence_of :username
  validates_uniqueness_of :username, :email, :allow_blank => true
  validates_format_of :username, :with => /^[-\w\._@]+$/i, :allow_blank => true, :message => "should only contain letters, numbers, or .-_@"
  validates_format_of :email, :with => /^[-a-z0-9_+\.]+\@([-a-z0-9]+\.)+[a-z0-9]{2,4}$/i
  validates_presence_of :password, :on => :create
  validates_confirmation_of :password
  validates_length_of :password, :minimum => 4, :allow_blank => true
  validates_presence_of :name

  has_one :account
  has_many :poolusers
  has_many :pickem_pools, :through => :poolusers  
  has_many :pickem_week_entries
  has_and_belongs_to_many :sites
  has_many :survivor_entries
  has_many :survivor_sessions, :through => :survivor_entries
  has_many :confidence_picks
  has_many :confidence_entries
  has_many :masters_pool_entries

  # login can be either username or email address
  def self.authenticate(login, pass)
    #user = find_by_username(login) || find_by_email(login)

    user = find_by_lowered_username(login.downcase) || find_by_email(login)
    return user if user && user.password_hash == user.encrypt_password(pass)
  end

  def encrypt_password(pass)
    BCrypt::Engine.hash_secret(pass, password_salt)
  end

  def balance
    unless account.nil?
      account.transactions.inject(0) {|acc, transaction| acc + transaction.amount}
    end
  end

  def pool_admin?(pool)
    id == pool.admin_id
  end

  def current_season_pickem_entries
    cur_season = DbConfig.get_value_by_key('CurrentSeason')
    pickem_week_entries.joins(:pickem_week).where("pickem_weeks.season = '#{cur_season}'").all 
  end

  def favorites_picked
    favorites = 0
    current_season_pickem_entries.each do |entry|
      entry.pickem_picks.each do |pick|
        if pick.picked_favorite?
          favorites += 1
        end
      end
    end

    favorites
  end

  def underdogs_picked
    underdogs = 0
    current_season_pickem_entries.each do |entry|
      entry.pickem_picks.each do |pick|
        if pick.picked_underdog?
          underdogs += 1
        end
      end
    end

    underdogs 
  end

  def current_survivor_entries(pool)
    survivor_entries.where("survivor_session_id = ? AND week >= ?", pool.current_session.id, pool.current_session.starting_week).all
  end
 
  def debit_for_survivor?(description)
    account.transactions.where("description LIKE '%#{description}%'").first.nil?
  end 
 
  def site_admin?
    !sites.empty? && sites[0].admin_id == id
  end 

  def find_masters_pool_entry_by_year(year=nil)
    if(year.nil?)
      year = DateTime.current.year.to_s
    end
   
    tourney = MastersTournament.find_by_year(year)
    pool = MastersPool.find_by_masters_tournament_id(tourney.id)

    masters_pool_entries.where("masters_pool_id = ?", pool.id).first
  end

  private

    def prepare_password
      unless password.blank?
        self.password_salt = BCrypt::Engine.generate_salt
        self.password_hash = encrypt_password(password)
      end
    end

    def lower_username
      unless username.blank?
        self.lowered_username = username.downcase
      end
    end

end
