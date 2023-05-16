# frozen_string_literal: true

class CreateComments < ActiveRecord::Migration[7.0]
  def change
    create_table :comments do |t|
      t.references :blog, null: false, foreign_key: true
      t.string :user_name, null: false
      t.text :comment

      t.timestamps
    end
  end
end
