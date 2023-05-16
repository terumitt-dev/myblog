# frozen_string_literal: true

class AddColumnsToBlogs < ActiveRecord::Migration[7.0]
  def change
    add_column :blogs, :title, :string, null: false
    add_column :blogs, :content, :text, null: false
    add_column :blogs, :category, :integer, null: false
  end
end
