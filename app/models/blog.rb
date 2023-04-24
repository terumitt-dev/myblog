# frozen_string_literal: true

class Blog < ApplicationRecord
  attribute :title, :string
  attribute :category, :integer
  attribute :content, :text

  enum category: { hobby: 1, tech: 2, other: 3 }

  def category_label
    category&.titleize || "Unknown Category"
  end

end
