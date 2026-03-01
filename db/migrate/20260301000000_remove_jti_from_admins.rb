# frozen_string_literal: true

class RemoveJtiFromAdmins < ActiveRecord::Migration[8.0]
  def change
    remove_index :admins, :jti if index_exists?(:admins, :jti)
    remove_column :admins, :jti, :string
  end
end
