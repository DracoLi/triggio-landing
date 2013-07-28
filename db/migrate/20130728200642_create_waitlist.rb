class CreateWaitlist < ActiveRecord::Migration
  def up
    create_table :wait_lists do |t|
      t.string :company_name
      t.string :email
      t.timestamps
    end
  end

  def down
    drop_table :wait_lists
  end
end
