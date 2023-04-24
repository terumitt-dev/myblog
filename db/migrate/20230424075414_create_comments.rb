class CreateComments < ActiveRecord::Migration[7.0]
  def change
    create_table :comments do |t|
      t.references :blogs, null: false, foreign_key: true
      t.string :other_user_name
      t.text :comment

      t.timestamps
    end
  end
end
