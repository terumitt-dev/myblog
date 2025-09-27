# frozen_string_literal: true

class Blog < ApplicationRecord
  has_many :comments, dependent: :destroy
  validates :title, :category, :content, presence: true
  enum :category, { uncategorized: 0, hobby: 1, tech: 2, other: 3 }, default: :uncategorized

  def self.import_from_mt(file)
    content = File.read(file.path, encoding: "UTF-8")
    entries = parse_mt_content(content)

    return 0 if entries.empty?

    transaction do
      entries.each do |entry|
        next if entry[:title].blank? || entry[:content].blank? # 空タイトル・空本文はスキップ

        date = parse_mt_date(entry[:date])
        Blog.create!(
          title: entry[:title],
          content: entry[:content],
          category: :uncategorized,
          created_at: date
        )
      rescue => e
        Rails.logger.warn "⚠️ Blog import failed for entry #{entry[:title]}: #{e.message}"
        next
      end
    end

    entries.count { |e| e[:title].present? && e[:content].present? }
  end

  def self.parse_mt_content(content)
    entries = []

    content.scan(
      /AUTHOR:\s*(.+?)\r?\nTITLE:\s*(.+?)\r?\n(?:.*?\r?\n)*?DATE:\s*(.+?)\r?\n(?:.*?\r?\n)*?BODY:\r?\n(.*?)(?:\r?\n-{5,}\r?\n|\z)/m
    ) do |_author, title, date, body|
      entries << {
        title: title.strip,
        content: body.gsub(/\r\n?/, "\n").strip, # 改行を統一してstrip
        date: date.strip
      }
    end

    entries
  end

  def self.parse_mt_date(date_str)
    return Time.zone.now if date_str.blank?

    case date_str
    when %r{\d{2}/\d{2}/\d{4} \d{2}:\d{2}:\d{2}} # 12/17/2024 19:00:00
      DateTime.strptime(date_str, "%m/%d/%Y %H:%M:%S")
    when /\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}/   # 2023-06-04 22:57:15
      DateTime.strptime(date_str, "%Y-%m-%d %H:%M:%S")
    else
      Time.zone.now
    end
  rescue => e
    Rails.logger.warn "⚠️ DATE parse failed: #{date_str} (#{e.message})"
    Time.zone.now
  end
end
