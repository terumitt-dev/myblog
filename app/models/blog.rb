# frozen_string_literal: true

require "uri"
require "nkf"

class Blog < ApplicationRecord
  has_many :comments, dependent: :destroy
  validates :title, :category, :content, presence: true
  enum :category, { uncategorized: 0, hobby: 1, tech: 2, other: 3 }, default: :uncategorized

  MAX_UPLOAD_SIZE = 5.megabytes

  def self.import_from_mt(uploaded_file)
    return 0 if uploaded_file.blank?

    content = NKF.nkf("-w", uploaded_file.read)

    entries = parse_mt_content(content)
    return 0 if entries.empty?

    successful_count = 0

    transaction do
      entries.each do |entry|
        safe_title   = sanitize_text(entry[:title])
        safe_content = sanitize_text(entry[:content])

        begin
          date = parse_mt_date(entry[:date])
          now  = Time.zone.now
          Blog.create!(
            title: safe_title,
            content: safe_content,
            category: :uncategorized,
            created_at: date,
            updated_at: now
          )
          successful_count += 1
        rescue => e
          Rails.logger.warn "⚠️ Blog import failed for an entry: #{e.class} #{e.message}"
          next
        end
      end
    end

    successful_count
  end

  # サニタイズ（タイトル・コンテンツ共通）
  def self.sanitize_text(text)
    ActionController::Base.helpers.sanitize(text.to_s, tags: [])
  end

  def self.parse_mt_content(content)
    entries = []

    content.scan(
      /AUTHOR:\s*(.+?)\r?\nTITLE:\s*(.+?)\r?\n(?:.*?\r?\n)*?DATE:\s*(.+?)\r?\n(?:.*?\r?\n)*?BODY:\r?\n(.*?)(?:\r?\n-{5,}\r?\n|\z)/m
    ) do |_author, title, date, body|
      entries << {
        title: title.strip,
        content: body.gsub(/\r\n?/, "\n").strip,
        date: date.strip
      }
    end

    entries
  end

  def self.parse_mt_date(date_str)
    return Time.zone.now if date_str.blank?

    case date_str
    when %r{\d{2}/\d{2}/\d{4} \d{2}:\d{2}:\d{2}}
      Time.zone.strptime(date_str, "%m/%d/%Y %H:%M:%S")
    when /\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}/
      Time.zone.strptime(date_str, "%Y-%m-%d %H:%M:%S")
    else
      Time.zone.now
    end
  rescue => e
    Rails.logger.warn "⚠️ DATE parse failed: #{date_str} (#{e.message})"
    Time.zone.now
  end
end
