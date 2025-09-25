# frozen_string_literal: true

class Blog < ApplicationRecord
  has_many :comments, dependent: :destroy
  validates :title, :category, :content, presence: true
  enum :category, { uncategorized: 0, hobby: 1, tech: 2, other: 3 }, default: :uncategorized

  def self.import_from_mt(file)
    content = File.read(file.path)
    entries = parse_mt_content(content)
    entries.each do |entry|
      Blog.create(
        title: entry[:title],
        content: entry[:content],
        category: entry[:category] || :uncategorized
      )
    end
  end

  def self.parse_mt_content(content)
    entries = []

    content.split("\n\n").each do |block|
      title_match = block.match(/^TITLE:\s*(.*)$/i)
      body_match  = block.match(/^BODY\s*:\s*(.*)$/im)
      date_match  = block.match(/^DATE\s*:\s*(.*)$/i)

      next unless title_match && body_match

      entries << {
        title: title_match[1].strip,
        content: body_match[1].strip,
        category: :uncategorized,
        date: date_match ? (Time.parse(date_match[1].strip) rescue nil) : nil
      }
    end

    entries
  end
end
