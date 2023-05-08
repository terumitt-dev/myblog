# frozen_string_literal: true

class Blog < ApplicationRecord
  has_many :comments, dependent: :destroy
  validates :title, :category, :content, presence: true
  enum category: { uncategorized: 0, hobby: 1, tech: 2, other: 3 }, _default: :uncategorized
end
