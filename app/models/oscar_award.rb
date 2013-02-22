class OscarAward < ActiveRecord::Base
  attr_accessible :description

  validates_presence_of :description
  validates_uniqueness_of :description

  has_many :oscar_nominations
  has_many :oscar_nominees, :through => :oscar_nominations
end
