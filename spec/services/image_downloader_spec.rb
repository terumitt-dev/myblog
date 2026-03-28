# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ImageDownloader do
  describe '.download_and_attach' do
    let(:blog) { Blog.create!(title: 'テスト', category: :tech, content: '本文') }

    context '許可されたホストの画像URLの場合' do
      let(:url) { 'https://cdn-ak.f.st-hatena.com/images/test.jpg' }

      it '画像をダウンロードしてActive Storageに保存しURLを返すこと' do
        stub_response = Net::HTTPResponse::CODE_TO_OBJ['200'].new('1.1', '200', 'OK')
        allow(stub_response).to receive(:[]).with('Content-Type').and_return('image/jpeg')
        allow(stub_response).to receive(:[]).with('Content-Length').and_return('100')
        allow(stub_response).to receive(:[]).with('Location').and_return(nil)
        allow(stub_response).to receive(:body).and_return('fake-image-data')

        http = instance_double(Net::HTTP)
        allow(Net::HTTP).to receive(:new).and_return(http)
        allow(http).to receive(:use_ssl=)
        allow(http).to receive(:open_timeout=)
        allow(http).to receive(:read_timeout=)
        allow(http).to receive(:get).and_return(stub_response)

        # Active Storageのblob作成とURL生成をモック
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
        stub_response = instance_double(Net::HTTPSuccess)
        allow(stub_response).to receive(:is_a?).and_return(false)
        allow(stub_response).to receive(:is_a?).with(Net::HTTPSuccess).and_return(true)
        allow(stub_response).to receive(:[]).with('Content-Type').and_return('text/html')
        allow(stub_response).to receive(:[]).with('Content-Length').and_return('13')
        allow(stub_response).to receive(:body).and_return('<html></html>')

        http = instance_double(Net::HTTP)
        allow(Net::HTTP).to receive(:new).and_return(http)
        allow(http).to receive(:use_ssl=)
        allow(http).to receive(:open_timeout=)
        allow(http).to receive(:read_timeout=)
        allow(http).to receive(:get).and_return(stub_response)

        result = ImageDownloader.download_and_attach(url, blog)
        expect(result).to be_nil
      end
    end

    context '画像サイズが上限を超える場合' do
      let(:url) { 'https://cdn-ak.f.st-hatena.com/images/large.jpg' }

      it 'nilを返すこと' do
        large_body = 'x' * (ImageDownloader::MAX_IMAGE_SIZE + 1)

        stub_response = instance_double(Net::HTTPSuccess)
        allow(stub_response).to receive(:is_a?).and_return(false)
        allow(stub_response).to receive(:is_a?).with(Net::HTTPSuccess).and_return(true)
        allow(stub_response).to receive(:[]).with('Content-Type').and_return('image/jpeg')
        allow(stub_response).to receive(:[]).with('Content-Length').and_return(large_body.bytesize.to_s)
        allow(stub_response).to receive(:body).and_return(large_body)

        http = instance_double(Net::HTTP)
        allow(Net::HTTP).to receive(:new).and_return(http)
        allow(http).to receive(:use_ssl=)
        allow(http).to receive(:open_timeout=)
        allow(http).to receive(:read_timeout=)
        allow(http).to receive(:get).and_return(stub_response)

        result = ImageDownloader.download_and_attach(url, blog)
        expect(result).to be_nil
      end
    end

    context 'HTTPエラーが発生した場合' do
      let(:url) { 'https://cdn-ak.f.st-hatena.com/images/error.jpg' }

      it 'nilを返すこと' do
        stub_response = instance_double(Net::HTTPNotFound)
        allow(stub_response).to receive(:is_a?).and_return(false)

        http = instance_double(Net::HTTP)
        allow(Net::HTTP).to receive(:new).and_return(http)
        allow(http).to receive(:use_ssl=)
        allow(http).to receive(:open_timeout=)
        allow(http).to receive(:read_timeout=)
        allow(http).to receive(:get).and_return(stub_response)

        result = ImageDownloader.download_and_attach(url, blog)
        expect(result).to be_nil
      end
    end

    context 'ネットワークエラーが発生した場合' do
      let(:url) { 'https://cdn-ak.f.st-hatena.com/images/timeout.jpg' }

      it 'nilを返すこと' do
        http = instance_double(Net::HTTP)
        allow(Net::HTTP).to receive(:new).and_return(http)
        allow(http).to receive(:use_ssl=)
        allow(http).to receive(:open_timeout=)
        allow(http).to receive(:read_timeout=)
        allow(http).to receive(:get).and_raise(Net::OpenTimeout.new('connection timed out'))

        result = ImageDownloader.download_and_attach(url, blog)
        expect(result).to be_nil
      end
    end
  end
end
