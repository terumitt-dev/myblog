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

    content.scan(
      /TITLE:\s*(.+?)\r?\nBODY:\s*(.+?)(?=\r?\nTITLE:|\z)/m
    ) do |title, body|
      title = title.gsub(/BASENAME:.*|STATUS:.*|ALLOW COMMENTS:.*|CONVERT BREAKS:.*|DATE:.*|IMAGE:.*|-----/i, '').strip

      body = body.gsub(/^-{5,}(\s*-+)?(\s*AUTHOR:.*)?$/i, '')
      body = body.strip

      entries << {
        title: title,
        content: body,
        category: :uncategorized
      }
    end

    entries
  end
end
