# frozen_string_literal: true

require "uri"

class Blog < ApplicationRecord
  has_many :comments, dependent: :destroy
  validates :title, :category, :content, presence: true
  enum :category, { uncategorized: 0, hobby: 1, tech: 2, other: 3 }, default: :uncategorized

  MAX_UPLOAD_SIZE = 5.megabytes

  def self.import_from_mt(uploaded_file)
    return 0 if uploaded_file.blank? || uploaded_file.size > MAX_UPLOAD_SIZE

    content = uploaded_file.read.force_encoding("UTF-8")
    entries = parse_mt_content(content)
    return 0 if entries.empty?

    successful_count = 0

    transaction do
      entries.each do |entry|
        safe_title = sanitize_title(entry[:title])
        safe_content = sanitize_content(entry[:content])

        begin
          date = parse_mt_date(entry[:date])
          Blog.create!(
            title: safe_title,
            content: safe_content,
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

  # サニタイズ：タイトル
  def self.sanitize_title(title)
    ActionController::Base.helpers.sanitize(title.to_s, tags: [])
  end

  # サニタイズ：コンテンツ
  def self.sanitize_content(content)
    sanitized = ActionController::Base.helpers.sanitize(
      content.to_s,
      tags: %w[p br img a ul ol li h1 h2 h3 pre code],
      attributes: %w[href src alt title]
    )

    # img/src チェック
    sanitized.gsub!(/<img [^>]*src="([^"]+)"[^>]*>/i) do |tag|
      begin
        uri = URI.parse($1)
        uri.scheme =~ /\Ahttps?\z/i ? tag : ""
      rescue URI::InvalidURIError
        ""
      end
    end

    # a/href チェック + rel/target 付与
    sanitized.gsub!(/<a [^>]*href="([^"]+)"[^>]*>/i) do |tag|
      begin
        uri = URI.parse($1)
        if uri.scheme =~ /\Ahttps?\z/i
          tag.sub(/<a /i, '<a target="_blank" rel="noopener noreferrer nofollow" ')
        else
          ""
        end
      rescue URI::InvalidURIError
        ""
      end
    end

    sanitized
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
