# frozen_string_literal: true

class Blog < ApplicationRecord
  attribute :title, :string
  attribute :category, :integer
  attribute :content, :text
end
