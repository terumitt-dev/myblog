class CreateJwtBlacklists < ActiveRecord::Migration[8.0]
  def change
    create_table :jwt_blacklists do |t|
      t.string :jti, null: false
      t.datetime :exp, null: false

      t.timestamps
      t.index :jti, unique: true
      t.index :exp
    end
  end
end
