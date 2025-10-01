# frozen_string_literal: true

require "uri"
require "nkf"

class Blog < ApplicationRecord
  has_many :comments, dependent: :destroy
  validates :title, :category, :content, presence: true
  enum :category, { uncategorized: 0, hobby: 1, tech: 2, other: 3 }, default: :uncategorized

  MAX_UPLOAD_SIZE = 5.megabytes

  def self.valid_mt_file?(uploaded_file)
    return false unless uploaded_file

    allowed_types = ["text/plain", "text/markdown", "application/octet-stream"]
    allowed_exts  = [".txt", ".text", ".md"]

    ext = File.extname(uploaded_file.original_filename).downcase
    mime = Marcel::MimeType.for(uploaded_file, name: uploaded_file.original_filename)

    content = uploaded_file.read
    uploaded_file.rewind
    is_text = content[0..1024].ascii_only? || !content[0..1024].each_byte.any?(&:zero?)

    allowed_types.include?(mime) && allowed_exts.include?(ext) && is_text
  end

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

    formats = [
      "%m/%d/%Y %H:%M:%S",   # 例: 12/31/2023 23:59:59
      "%Y-%m-%d %H:%M:%S",   # 例: 2023-12-31 23:59:59
      "%Y/%m/%d %H:%M:%S",   # 例: 2023/12/31 23:59:59
      "%a %b %d %H:%M:%S %Y" # 例: Sun Dec 31 23:59:59 2023
    ]

    formats.each do |fmt|
      begin
        return Time.zone.strptime(date_str, fmt)
      rescue ArgumentError
        next
      end
    end

    begin
      parsed = Time.zone.parse(date_str)
      return parsed if parsed.present?
    rescue => e
      Rails.logger.warn "⚠️ Time.zone.parse also failed: #{date_str} (#{e.message})"
    end

    Rails.logger.warn "⚠️ DATE parse failed, fallback to now: #{date_str}"
    Time.zone.now
  end
end
