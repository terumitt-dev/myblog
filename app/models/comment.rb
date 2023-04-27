# frozen_string_literal: true

class Comment < ApplicationRecord
  belongs_to :blog
  validates :blog_id, :other_user_name, presence: true
end
