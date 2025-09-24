# frozen_string_literal: true

class Blog < ApplicationRecord
  has_many :comments, dependent: :destroy
  validates :title, :category, :content, presence: true
  enum :category, { uncategorized: 0, hobby: 1, tech: 2, other: 3 }, default: :uncategorized

  def self.import_from_mt(file)
    content = File.read(file.path)
    entries = parse_mt_content(content) # 独自解析メソッド

    entries.each do |entry|
      create!(
        title: entry[:title],
        content: entry[:content],
        category: entry[:category] || :uncategorized,
        created_at: entry[:date] || Time.current
      )
    end
  end

  def self.parse_mt_content(content)
    entries = []
    content.split("\n\n").each do |block|
      title_match = block.match(/Title: (.*)/)
      body_match  = block.match(/Body: (.*)/)
      date_match  = block.match(/Date: (.*)/)

      next unless title_match && body_match

      entries << {
        title: title_match[1],
        content: body_match[1],
        category: :uncategorized,
        date: date_match&.to_time
      }
    end
    entries
  end
end
