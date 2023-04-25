# frozen_string_literal: true

class Blog < ApplicationRecord
  enum category: { uncategorized: 0, hobby: 1, tech: 2, other: 3 }, _default: 0

  def category_label
    category&.titleize
  end
end
