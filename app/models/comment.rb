# frozen_string_literal: true

class Comment < ApplicationRecord
  belongs_to :blog
  validates :blog_id, presence: true
end
