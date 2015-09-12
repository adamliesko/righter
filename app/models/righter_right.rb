class RighterRight < ActiveRecord::Base
  has_many :righter_rights_righter_roles, dependent: :destroy
  has_many :righter_roles, -> { uniq }, through: :righter_rights_righter_roles
  belongs_to :parent, class_name: 'RighterRight', foreign_key: :parent_id

  scope :top_level_rights, lambda {
    where parent_id: nil
  }

  scope :visible, lambda {
    where hidden: [false, nil]
  }

  serialize :actions, Array
  validates :name, uniqueness: true

  after_save do
    RighterRight.clear_cache
  end

  after_create do
    RighterRight.clear_cache
  end

  after_destroy do
    RighterRight.clear_cache
  end

  @@cache = nil

  def self.load_cache
    unless @@cache
      @@cache = {}
      RighterRight.find_each do |right|
        @@cache[right.name.to_sym] = right
      end
    end
  end

  def self.cached_find_by_name(name)
    load_cache
    @@cache[name.to_sym]
  end

  def self.clear_cache
    @@cache = nil
  end

  validate :validate_cycles

  def validate_cycles(receiver = nil)
    return unless parent_id
    if receiver
      if parent == receiver
        receiver.errors.add :righter_right, "disallowed to create loops, collision with RighterRight #{name}"
      else
        parent.validate_cycles receiver
      end
    else
      parent.validate_cycles self
    end
  end

  def add_access_to(opts = {})
    fail RighterError.new('controller cannot be nil') unless opts[:controller]
    fail RighterError.new('actions should be in form of an array') unless opts[:actions].class == Array
    self.controller = opts[:controller]
    self.actions = opts[:actions]
    save!
  end

  def children
    self.class.where parent_id: id
  end
end
