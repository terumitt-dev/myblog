# frozen_string_literal: true

class Blog < ApplicationRecord
  attribute :title, :string
  attribute :category, :integer
  attribute :content, :text

  def category_label
    case category
    when 1
      "Hobby"
    when 2
      "Tech"
    when 3
      "Other"
    else
      "Unknown Category"
    end
  end
end
