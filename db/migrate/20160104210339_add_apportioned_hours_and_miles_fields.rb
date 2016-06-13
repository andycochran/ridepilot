class AddApportionedHoursAndMilesFields < ActiveRecord::Migration
  def change
    add_column :trips, :apportioned_duration, :decimal, precision: 7, scale: 2
    add_column :trips, :apportioned_mileage, :decimal, precision: 9, scale: 2
  end
end
