# frozen_string_literal: true

class AddColumnsToBlogs < ActiveRecord::Migration[7.0]
  def change
    change_table :blogs, bulk: true do |t|
      t.string  :title,    null: false, default: ''
      t.text    :content,  null: false, default: ''
      t.integer :category, null: false, default: 0
    end
  end
end
