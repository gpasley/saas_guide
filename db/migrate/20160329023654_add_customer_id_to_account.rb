class AddCustomerIdToAccount < ActiveRecord::Migration
  def change
    add_column :accounts, :customer_id, :string
    add_column :accounts, :active_until, :datetime
  end
end
