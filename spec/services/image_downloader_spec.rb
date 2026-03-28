# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ImageDownloader do
  describe '.download_and_attach' do
    let(:blog) { Blog.create!(title: 'テスト', category: :tech, content: '本文') }

    # request_getのブロック形式をモックするヘルパー
    def stub_streaming_response(http, response)
      allow(http).to receive(:request_get).and_yield(response)
    end

    def stub_http(http_double)
      allow(Net::HTTP).to receive(:new).and_return(http_double)
      allow(http_double).to receive(:use_ssl=)
      allow(http_double).to receive(:open_timeout=)
      allow(http_double).to receive(:read_timeout=)
    end

    def make_success_response(body:, content_type: 'image/jpeg', content_length: nil)
      response = Net::HTTPResponse::CODE_TO_OBJ['200'].new('1.1', '200', 'OK')
      allow(response).to receive(:[]).with('Content-Type').and_return(content_type)
      allow(response).to receive(:[]).with('Content-Length').and_return(content_length || body.bytesize.to_s)
      allow(response).to receive(:read_body).and_yield(body)
      allow(response).to receive(:body).and_return(body)
      response
    end

    context '許可されたホストの画像URLの場合' do
      let(:url) { 'https://cdn-ak.f.st-hatena.com/images/test.jpg' }

      it '画像をダウンロードしてActive Storageに保存しURLを返すこと' do
        response = make_success_response(body: 'fake-image-data')

        http = instance_double(Net::HTTP)
        stub_http(http)
        stub_streaming_response(http, response)

        blob = instance_double(ActiveStorage::Blob)
        allow(ActiveStorage::Blob).to receive(:create_and_upload!).and_return(blob)
        allow(blog.images).to receive(:attach)
        allow(Rails.application.routes.url_helpers).to receive(:rails_blob_path)
          .with(blob, only_path: true)
          .and_return('/rails/active_storage/blobs/xxx/test.jpg')

        result = ImageDownloader.download_and_attach(url, blog)

        expect(result).to eq('/rails/active_storage/blobs/xxx/test.jpg')
        expect(ActiveStorage::Blob).to have_received(:create_and_upload!)
        expect(blog.images).to have_received(:attach).with(blob)
      end
    end

    context '許可されていないホストの場合' do
      let(:url) { 'https://evil.com/images/malware.jpg' }

      it 'nilを返すこと' do
        result = ImageDownloader.download_and_attach(url, blog)
        expect(result).to be_nil
      end
    end

    context '無効なURLの場合' do
      it 'nilを返すこと' do
        expect(ImageDownloader.download_and_attach('not-a-url', blog)).to be_nil
      end

      it 'FTPスキームの場合nilを返すこと' do
        expect(ImageDownloader.download_and_attach('ftp://cdn-ak.f.st-hatena.com/file.jpg', blog)).to be_nil
      end
    end

    context '許可されていないContent-Typeの場合' do
      let(:url) { 'https://cdn-ak.f.st-hatena.com/files/test.html' }

      it 'nilを返すこと' do
        response = make_success_response(body: '<html></html>', content_type: 'text/html')

        http = instance_double(Net::HTTP)
        stub_http(http)
        stub_streaming_response(http, response)

        result = ImageDownloader.download_and_attach(url, blog)
        expect(result).to be_nil
      end
    end

    context '画像サイズが上限を超える場合（ストリーミングで中断）' do
      let(:url) { 'https://cdn-ak.f.st-hatena.com/images/large.jpg' }

      it 'nilを返すこと' do
        # Content-Lengthが大きい場合は事前チェックで弾かれる
        response = Net::HTTPResponse::CODE_TO_OBJ['200'].new('1.1', '200', 'OK')
        allow(response).to receive(:[]).with('Content-Type').and_return('image/jpeg')
        allow(response).to receive(:[]).with('Content-Length').and_return((ImageDownloader::MAX_IMAGE_SIZE + 1).to_s)
        allow(response).to receive(:read_body)

        http = instance_double(Net::HTTP)
        stub_http(http)
        stub_streaming_response(http, response)

        result = ImageDownloader.download_and_attach(url, blog)
        expect(result).to be_nil
      end
    end

    context 'HTTPエラーが発生した場合' do
      let(:url) { 'https://cdn-ak.f.st-hatena.com/images/error.jpg' }

      it 'nilを返すこと' do
        response = Net::HTTPResponse::CODE_TO_OBJ['404'].new('1.1', '404', 'Not Found')

        http = instance_double(Net::HTTP)
        stub_http(http)
        stub_streaming_response(http, response)

        result = ImageDownloader.download_and_attach(url, blog)
        expect(result).to be_nil
      end
    end

    context 'ネットワークエラーが発生した場合' do
      let(:url) { 'https://cdn-ak.f.st-hatena.com/images/timeout.jpg' }

      it 'nilを返すこと' do
        http = instance_double(Net::HTTP)
        stub_http(http)
        allow(http).to receive(:request_get).and_raise(Net::OpenTimeout.new('connection timed out'))

        result = ImageDownloader.download_and_attach(url, blog)
        expect(result).to be_nil
      end
    end
  end
end
