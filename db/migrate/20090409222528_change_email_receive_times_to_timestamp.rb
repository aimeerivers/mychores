class ChangeEmailReceiveTimesToTimestamp < ActiveRecord::Migration
  def self.up
    change_column :preferences, :email_time, :datetime, :default => '2009-01-01 08:00:00'
    execute "UPDATE preferences SET email_time = CONCAT('2009-01-01 ', email_time_gmt)"
    remove_column :preferences, :email_time_gmt
  end

  def self.down
    raise ActiveRecord::IrreversibleMigration
  end
end
