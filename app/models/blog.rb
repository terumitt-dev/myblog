# frozen_string_literal: true

require "uri"
require "nkf"

class Blog < ApplicationRecord
  has_many :comments, dependent: :destroy
  validates :title, :category, :content, presence: true
  enum :category, { uncategorized: 0, hobby: 1, tech: 2, other: 3 }, default: :uncategorized

  MAX_UPLOAD_SIZE = 5.megabytes
  ALLOWED_EXTENSIONS = %w[.txt]
  ALLOWED_MIME_TYPES = %w[text/plain]

  # --- ファイルバリデーション ---
  def self.valid_mt_file?(uploaded_file)
    return false unless uploaded_file
    return false if uploaded_file.size > MAX_UPLOAD_SIZE

    ext = File.extname(uploaded_file.original_filename).downcase
    mime = Marcel::MimeType.for(uploaded_file, name: uploaded_file.original_filename)

    begin
      content = uploaded_file.read
      uploaded_file.rewind
    rescue => e
      Rails.logger.warn "⚠️ Failed to read uploaded file: #{e.message}"
      return false
    end

    is_text = content[0..1024].ascii_only? || !content[0..1024].each_byte.any?(&:zero?)

    ALLOWED_EXTENSIONS.include?(ext) && ALLOWED_MIME_TYPES.include?(mime) && is_text
  end

  # --- MTファイルからのインポート ---
  def self.import_from_mt(uploaded_file)
    return 0 unless valid_mt_file?(uploaded_file)

    content = nil
    begin
      content = NKF.nkf("-w", uploaded_file.read)
    rescue => e
      Rails.logger.warn "⚠️ Failed to convert MT file to UTF-8: #{e.message}"
      return 0
    ensure
      uploaded_file.rewind
    end

    # BOM除去
    content.sub!(/\A\uFEFF/, "")

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

  # --- タグ除去サニタイズ ---
  def self.sanitize_text(text)
    ActionController::Base.helpers.sanitize(text.to_s, tags: [])
  end

  # --- MTパース（堅牢化） ---
  def self.parse_mt_content(content)
    entries = []

    content.scan(
      /AUTHOR:\s*(.*?)\r?\nTITLE:\s*(.*?)\r?\n(?:.*?\r?\n)*?DATE:\s*(.*?)\r?\n(?:.*?\r?\n)*?BODY:\r?\n(.*?)(?:\r?\n-{3,}\r?\n|\z)/m
    ) do |_author, title, date, body|
      entries << {
        title: title.to_s.strip,
        content: body.to_s.gsub(/\r\n?/, "\n").strip,
        date: date.to_s.strip
      }
    end

    entries
  end

  # --- 日付パース（複数フォーマット対応） ---
  def self.parse_mt_date(date_str)
    return Time.zone.now if date_str.blank?

    formats = [
      "%m/%d/%Y %H:%M:%S",
      "%Y-%m-%d %H:%M:%S",
      "%Y/%m/%d %H:%M:%S",
      "%a %b %d %H:%M:%S %Y"
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
