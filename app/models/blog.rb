# frozen_string_literal: true

require "uri"
require "nkf"
require "cgi"

class Blog < ApplicationRecord
  has_many :comments, dependent: :destroy
  validates :title, :category, :content, presence: true
  enum :category, { uncategorized: 0, hobby: 1, tech: 2, other: 3 }, default: :uncategorized

  MAX_UPLOAD_SIZE = 5.megabytes
  ALLOWED_EXTENSIONS = %w[.txt]
  ALLOWED_MIME_TYPES = %w[text/plain]
  MAX_ENTRIES_COUNT = 1000
  MAX_ENTRY_SIZE = 100.kilobytes

  # --- ファイルバリデーション ---
  def self.valid_mt_file?(uploaded_file)
    return false unless uploaded_file
    return false if uploaded_file.size.zero?

    ext = File.extname(uploaded_file.original_filename.to_s).downcase

    # MIME判定の強化
    begin
      mime = Marcel::MimeType.for(uploaded_file, name: uploaded_file.original_filename) || ""
      uploaded_file.rewind
    rescue => e
      Rails.logger.warn "⚠️ MIME detection failed: #{e.message}"
      return false
    end

    ext_ok  = ALLOWED_EXTENSIONS.include?(ext)
    mime_ok = ALLOWED_MIME_TYPES.include?(mime)

    ext_ok && mime_ok
  end

  # --- MTファイルからのインポート ---
  def self.import_from_mt(uploaded_file)
    return { success: 0, errors: [], error_type: :invalid_file } unless valid_mt_file?(uploaded_file)

    content = nil
    begin
      content = NKF.nkf("-w", uploaded_file.read)
    rescue => e
      Rails.logger.warn "⚠️ Failed to convert MT file to UTF-8: #{e.message}"
      return { success: 0, errors: ["File encoding conversion failed"], error_type: :encoding_error }
    ensure
      uploaded_file.rewind
    end

    # BOM除去
    content.sub!(/\A\uFEFF/, "")

    entries = parse_mt_content(content)
    if entries.empty?
      return { success: 0, errors: ["No valid entries found in file"], error_type: :no_entries }
    end

    # エントリ数上限チェック
    if entries.size > MAX_ENTRIES_COUNT
      Rails.logger.warn "⚠️ Too many entries: #{entries.size} (max: #{MAX_ENTRIES_COUNT})"
      return { success: 0, errors: ["Too many entries in file (max: #{MAX_ENTRIES_COUNT})"], error_type: :too_many_entries }
    end

    import_result = { success: 0, errors: [] }

    transaction do
      entries.each_with_index do |entry, index|
        begin
          safe_title = sanitize_text(entry[:title])
          safe_content = sanitize_text(entry[:content])

          # エントリサイズチェック
          entry_size = safe_title.bytesize + safe_content.bytesize
          if entry_size > MAX_ENTRY_SIZE
            Rails.logger.warn "⚠️ Entry #{index + 1} too large: #{entry_size} bytes"
            import_result[:errors] << "Entry #{index + 1}: Content too large (#{entry_size} bytes)"
            next
          end

          date = parse_mt_date(entry[:date])
          now = Time.zone.now

          Blog.create!(
            title: safe_title,
            content: safe_content,
            category: :uncategorized,
            created_at: date,
            updated_at: now
          )
          import_result[:success] += 1

        rescue ActiveRecord::RecordInvalid => e
          error_msg = e.record.errors.full_messages.join(", ")
          Rails.logger.warn "⚠️ Blog validation failed for entry #{index + 1}: #{error_msg}"
          import_result[:errors] << "Entry #{index + 1}: #{error_msg}"
        rescue => e
          Rails.logger.warn "⚠️ Blog import failed for entry #{index + 1}: #{e.class} #{e.message}"
          import_result[:errors] << "Entry #{index + 1}: Import failed (#{e.class.name})"
        end
      end
    end

    import_result
  end

  # --- HTMLエンティティをデコードするサニタイズ ---
  def self.sanitize_text(text)
    sanitized = ActionController::Base.helpers.sanitize(text.to_s, tags: [])
    # CGI.unescapeHTMLで基本的なエンティティをデコード + 足りない&nbsp;を手動追加
    CGI.unescapeHTML(sanitized).gsub('&nbsp;', ' ').strip
  end

  # --- MTパース（堅牢化） ---
  def self.parse_mt_content(content)
    entries = []

    # より堅牢な区切り文字でエントリを分割
    entry_blocks = content.split(/\r?\n-{5,}\r?\n/)

    entry_blocks.each_with_index do |block, index|
      next if block.strip.empty?

      begin
        entry = parse_mt_entry_block(block.strip)
        entries << entry if entry
      rescue => e
        Rails.logger.warn "⚠️ Failed to parse entry block #{index + 1}: #{e.message}"
        next
      end
    end

    # 従来の正規表現方式もフォールバック
    if entries.empty?
      content.scan(
        /AUTHOR:\s*(.*?)\r?\nTITLE:\s*(.*?)\r?\n(?:.*?\r?\n)*?DATE:\s*(.*?)\r?\n(?:.*?\r?\n)*?BODY:\r?\n(.*?)(?:\r?\n-{3,}\r?\n|\z)/m
      ) do |_author, title, date, body|
        entries << {
          title: title.to_s.strip,
          content: body.to_s.gsub(/\r\n?/, "\n").strip,
          date: date.to_s.strip
        }
      end
    end

    entries
  end

  # --- MTエントリブロックのパース（フィールド順序に依存しない） ---
  def self.parse_mt_entry_block(block)
    fields = {}
    current_field = nil
    current_content = []

    block.split(/\r?\n/).each do |line|
      if line =~ /^([A-Z]+):\s*(.*)$/
        # 前のフィールドを保存
        if current_field
          fields[current_field.downcase.to_sym] = current_content.join("\n").strip
        end
        # 新しいフィールドを開始
        current_field = $1
        current_content = [$2]
      elsif current_field
        current_content << line
      end
    end

    # 最後のフィールドを保存
    if current_field
      fields[current_field.downcase.to_sym] = current_content.join("\n").strip
    end

    # 必須フィールドチェック
    return nil unless fields[:title] && fields[:body]

    {
      title: fields[:title],
      content: fields[:body].gsub(/\r\n?/, "\n"),
      date: fields[:date] || ""
    }
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
