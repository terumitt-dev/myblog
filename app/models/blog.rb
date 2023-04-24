# frozen_string_literal: true

class Blog < ApplicationRecord
  attribute :title, :string
  attribute :category, :integer, default: 0
  attribute :content, :text

  enum category: { uncategorized: 0, hobby: 1, tech: 2, other: 3 }

  def category_label
    category&.titleize
  end
end
