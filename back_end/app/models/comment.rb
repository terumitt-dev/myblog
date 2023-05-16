# frozen_string_literal: true

class Comment < ApplicationRecord
  belongs_to :blog
  validates :user_name, presence: true
end
