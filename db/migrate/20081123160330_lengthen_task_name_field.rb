class LengthenTaskNameField < ActiveRecord::Migration
  def self.up
    change_column :tasks, :name, :string, :limit => 255
  end

  def self.down
    change_column :tasks, :name, :string, :limit => 30
  end
end
