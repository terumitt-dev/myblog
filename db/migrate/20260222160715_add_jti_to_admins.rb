class AddJtiToAdmins < ActiveRecord::Migration[8.0]
  def change
    add_column :admins, :jti, :string
    add_index :admins, :jti, unique: true
  end
end
