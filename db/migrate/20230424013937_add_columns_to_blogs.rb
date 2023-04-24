# frozen_string_literal: true

class AddColumnsToBlogs < ActiveRecord::Migration[7.0]
  def change
    add_column :blogs, :title, :string
    add_column :blogs, :content, :text
    add_column :blogs, :category, :integer
  end
end
