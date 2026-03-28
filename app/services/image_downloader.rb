# frozen_string_literal: true

require "net/http"
require "uri"

class ImageDownloader
  ALLOWED_HOSTS = %w[
    cdn-ak.f.st-hatena.com
    cdn.blog.st-hatena.com
  ].freeze

  MAX_IMAGE_SIZE = 10.megabytes
  ALLOWED_CONTENT_TYPES = %w[image/jpeg image/png image/gif image/webp].freeze
  DOWNLOAD_TIMEOUT = 30
  MAX_REDIRECTS = 3

  # 外部URLから画像をダウンロードしてActive Storageに保存し、blobのURLを返す
  # 対象外のホストやエラー時はnilを返す
  def self.download_and_attach(url, blog)
    uri = parse_url(url)
    return nil unless uri && ALLOWED_HOSTS.include?(uri.host)

    response = fetch_with_redirects(uri)
    return nil unless response

    # Content-Lengthで事前サイズチェック（メモリ節約）
    content_length = response["Content-Length"]&.to_i
    return nil if content_length && content_length > MAX_IMAGE_SIZE

    content_type = response["Content-Type"]&.split(";")&.first&.strip
    return nil unless ALLOWED_CONTENT_TYPES.include?(content_type)
    return nil if response.body.bytesize > MAX_IMAGE_SIZE

    filename = File.basename(uri.path)
    blob = ActiveStorage::Blob.create_and_upload!(
      io: StringIO.new(response.body),
      filename: filename,
      content_type: content_type
    )
    blog.images.attach(blob)

    Rails.application.routes.url_helpers.rails_blob_path(blob, only_path: true)
  rescue StandardError => e
    Rails.logger.warn "ImageDownloader: Failed to download #{url}: #{e.message}"
    nil
  end

  def self.parse_url(url)
    uri = URI.parse(url)
    return nil unless uri.is_a?(URI::HTTP) || uri.is_a?(URI::HTTPS)

    uri
  rescue URI::InvalidURIError
    nil
  end
  private_class_method :parse_url

  # リダイレクト対応のfetch（最大MAX_REDIRECTS回まで追跡）
  def self.fetch_with_redirects(uri, redirect_count = 0)
    return nil if redirect_count > MAX_REDIRECTS

    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = (uri.scheme == "https")
    http.open_timeout = DOWNLOAD_TIMEOUT
    http.read_timeout = DOWNLOAD_TIMEOUT

    response = http.get(uri.request_uri)

    case response
    when Net::HTTPSuccess
      response
    when Net::HTTPRedirection
      redirect_url = response["Location"]
      return nil unless redirect_url

      new_uri = parse_url(redirect_url)
      return nil unless new_uri

      fetch_with_redirects(new_uri, redirect_count + 1)
    else
      nil
    end
  rescue StandardError => e
    Rails.logger.warn "ImageDownloader: HTTP error for #{uri}: #{e.message}"
    nil
  end
  private_class_method :fetch_with_redirects
end
