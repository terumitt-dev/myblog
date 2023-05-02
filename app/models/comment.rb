# frozen_string_literal: true

class Comment < ApplicationRecord
  belongs_to :blog
  validates :other_user_name, presence: true
end
