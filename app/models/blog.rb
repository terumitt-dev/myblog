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

    # 正規表現で記事単位を取得
    content.scan(
      /TITLE:\s*(.+?)\r?\nBODY:\s*(.+?)(?:\r?\nDATE:\s*(.+?))?(?=\r?\nTITLE:|\z)/m
    ) do |title, body, date|
      entries << {
        title: title.strip,
        content: body.strip,
        category: :uncategorized,
        date: date ? (Time.parse(date.strip) rescue nil) : nil
      }
    end

    entries
  end
end
