class AddConstraintsToJwtBlacklists < ActiveRecord::Migration[8.0]
  def change
    # jti と exp を NOT NULL に変更
    change_column_null :jwt_blacklists, :jti, false
    change_column_null :jwt_blacklists, :exp, false
    
    # exp にインデックスを追加（期限切れレコードの削除クエリを高速化）
    add_index :jwt_blacklists, :exp
  end
end
