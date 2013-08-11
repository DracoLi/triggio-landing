class AddSharedToWaitlist < ActiveRecord::Migration
  def change
    add_column :wait_lists, :shared, :boolean, default: false
  end
end
