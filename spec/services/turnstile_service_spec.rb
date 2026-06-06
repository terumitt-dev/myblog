# frozen_string_literal: true

require 'rails_helper'

RSpec.describe TurnstileService do
  describe '.verify' do
    let(:token) { 'dummy-token' }
    let(:remote_ip) { '203.0.113.10' }

    # Net::HTTP のレスポンスを差し替えるヘルパー (image_downloader_spec.rb と同じ方針)
    def stub_http(http_double)
      allow(Net::HTTP).to receive(:new).and_return(http_double)
      allow(http_double).to receive(:use_ssl=)
      allow(http_double).to receive(:open_timeout=)
      allow(http_double).to receive(:read_timeout=)
      allow(http_double).to receive(:write_timeout=)
    end

    def stub_request_returning(http, response)
      allow(http).to receive(:request).and_return(response)
    end

    def make_response(code, body:)
      response = Net::HTTPResponse::CODE_TO_OBJ[code].new('1.1', code, 'OK')
      allow(response).to receive(:body).and_return(body)
      response
    end

    context 'siteverify が success: true を返した場合' do
      it 'ALLOWED_HOSTNAMES が空なら hostname を見ずに true を返すこと' do
        http = instance_double(Net::HTTP)
        stub_http(http)
        stub_request_returning(http, make_response('200', body: { success: true }.to_json))

        expect(described_class.verify(token, remote_ip: remote_ip)).to be true
      end
    end

    context 'ALLOWED_HOSTNAMES が設定されている場合' do
      it 'hostname が allow list に含まれていれば true を返すこと' do
        stub_const('TurnstileService::ALLOWED_HOSTNAMES', %w[go-lilaregard.com www.go-lilaregard.com])

        http = instance_double(Net::HTTP)
        stub_http(http)
        stub_request_returning(http, make_response('200', body: { success: true, hostname: 'go-lilaregard.com' }.to_json))

        expect(described_class.verify(token, remote_ip: remote_ip)).to be true
      end

      it 'hostname が allow list に含まれていなければ false を返すこと (fail-closed)' do
        stub_const('TurnstileService::ALLOWED_HOSTNAMES', %w[go-lilaregard.com])

        http = instance_double(Net::HTTP)
        stub_http(http)
        stub_request_returning(http, make_response('200', body: { success: true, hostname: 'evil.example.com' }.to_json))

        expect(described_class.verify(token, remote_ip: remote_ip)).to be false
      end

      it 'hostname がレスポンスに含まれていなければ false を返すこと (fail-closed)' do
        stub_const('TurnstileService::ALLOWED_HOSTNAMES', %w[go-lilaregard.com])

        http = instance_double(Net::HTTP)
        stub_http(http)
        stub_request_returning(http, make_response('200', body: { success: true }.to_json))

        expect(described_class.verify(token, remote_ip: remote_ip)).to be false
      end
    end

    context 'siteverify が success: false を返した場合' do
      it 'false を返すこと' do
        http = instance_double(Net::HTTP)
        stub_http(http)
        stub_request_returning(http, make_response('200', body: { success: false, 'error-codes': ['invalid-input-response'] }.to_json))

        expect(described_class.verify(token, remote_ip: remote_ip)).to be false
      end
    end

    context 'token が空文字の場合' do
      it 'HTTP を叩かずに false を返すこと' do
        expect(Net::HTTP).not_to receive(:new)
        expect(described_class.verify('', remote_ip: remote_ip)).to be false
      end
    end

    context 'token が nil の場合' do
      it 'HTTP を叩かずに false を返すこと' do
        expect(Net::HTTP).not_to receive(:new)
        expect(described_class.verify(nil, remote_ip: remote_ip)).to be false
      end
    end

    context 'siteverify が HTTP エラー (500) を返した場合' do
      it 'false を返すこと (fail-closed)' do
        http = instance_double(Net::HTTP)
        stub_http(http)
        stub_request_returning(http, make_response('500', body: ''))

        expect(described_class.verify(token, remote_ip: remote_ip)).to be false
      end
    end

    context 'siteverify が timeout した場合' do
      it 'Net::OpenTimeout でも false を返すこと (fail-closed)' do
        http = instance_double(Net::HTTP)
        stub_http(http)
        allow(http).to receive(:request).and_raise(Net::OpenTimeout)

        expect(described_class.verify(token, remote_ip: remote_ip)).to be false
      end

      # Net::ReadTimeout は Ruby 3.2+ では Timeout::Error < RuntimeError < StandardError なので
      # rescue StandardError で捕捉される。古い Ruby (< 3.1) では別系統だったため、
      # Ruby アップグレードでの回帰を防ぐ目的で明示的にテストする。
      it 'Net::ReadTimeout でも false を返すこと (fail-closed)' do
        http = instance_double(Net::HTTP)
        stub_http(http)
        allow(http).to receive(:request).and_raise(Net::ReadTimeout)

        expect(described_class.verify(token, remote_ip: remote_ip)).to be false
      end
    end

    context 'siteverify が不正な JSON を返した場合' do
      it 'false を返すこと (fail-closed)' do
        http = instance_double(Net::HTTP)
        stub_http(http)
        stub_request_returning(http, make_response('200', body: '<html>not json</html>'))

        expect(described_class.verify(token, remote_ip: remote_ip)).to be false
      end
    end
  end
end
