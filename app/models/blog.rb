# frozen_string_literal: true

class Blog < ApplicationRecord
  has_many :comments, dependent: :destroy
  validates :title, :category, :content, presence: true
  enum :category, { uncategorized: 0, hobby: 1, tech: 2, other: 3 }, default: :uncategorized

  def self.import_from_mt(file)
    begin
      content = File.read(file.path, encoding: "UTF-8")
    rescue => e
      Rails.logger.error "⚠️ Failed to read file: #{e.message}"
      return 0
    end

    entries = parse_mt_content(content)
    return 0 if entries.empty?

    successful_count = 0

    transaction do
      entries.each do |entry|
        next if entry[:title].blank? || entry[:content].blank? # 空タイトル・空本文はスキップ

        begin
          date = parse_mt_date(entry[:date])
          Blog.create!(
            title: entry[:title],
            content: entry[:content],
            category: :uncategorized,
            created_at: date
          )
          successful_count += 1
        rescue => e
          Rails.logger.warn "⚠️ Blog import failed for entry #{entry[:title]}: #{e.message}"
          next
        end
      end
    end

    successful_count
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
      Time.zone.strptime(date_str, "%m/%d/%Y %H:%M:%S")
    when /\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}/   # 2023-06-04 22:57:15
      Time.zone.strptime(date_str, "%Y-%m-%d %H:%M:%S")
    else
      Time.zone.now
    end
  rescue => e
    Rails.logger.warn "⚠️ DATE parse failed: #{date_str} (#{e.message})"
    Time.zone.now
  end
end
