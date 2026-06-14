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

    context 'token が String 以外の場合 (Hash, Array, Integer 等)' do
      it 'HTTP を叩かずに false を返すこと (型攻撃の防御)' do
        expect(Net::HTTP).not_to receive(:new)
        expect(described_class.verify({ nested: 'value' }, remote_ip: remote_ip)).to be false
        expect(described_class.verify(['x'], remote_ip: remote_ip)).to be false
        expect(described_class.verify(123, remote_ip: remote_ip)).to be false
      end
    end

    context 'token が MAX_TOKEN_BYTESIZE を超える場合' do
      it 'HTTP を叩かずに false を返すこと (増幅攻撃の防御)' do
        oversized = 'a' * (TurnstileService::MAX_TOKEN_BYTESIZE + 1)
        expect(Net::HTTP).not_to receive(:new)
        expect(described_class.verify(oversized, remote_ip: remote_ip)).to be false
      end

      it 'ちょうど MAX_TOKEN_BYTESIZE バイトなら HTTP を叩くこと (境界値)' do
        exact = 'a' * TurnstileService::MAX_TOKEN_BYTESIZE
        http = instance_double(Net::HTTP)
        stub_http(http)
        stub_request_returning(http, make_response('200', body: { success: true }.to_json))

        expect(described_class.verify(exact, remote_ip: remote_ip)).to be true
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

  # boot 時の TURNSTILE_ALLOWED_HOSTNAMES 必須化を検証する。
  # 実体は class 読み込み時に走るが、validate_allowed_hostnames! を private class method
  # として切り出してあるので、メソッド単体で挙動を確認する。
  describe '.validate_allowed_hostnames! (boot-time fail-fast)' do
    context '本番環境かつ ENV が空文字の場合' do
      before { allow(Rails.env).to receive(:production?).and_return(true) }

      it '設定漏れを検知して raise すること' do
        expect { described_class.send(:validate_allowed_hostnames!, '') }
          .to raise_error(RuntimeError, /TURNSTILE_ALLOWED_HOSTNAMES must not be blank in production/)
      end

      it '空白だけの値も raise すること' do
        expect { described_class.send(:validate_allowed_hostnames!, '  ') }
          .to raise_error(RuntimeError, /TURNSTILE_ALLOWED_HOSTNAMES must not be blank in production/)
      end
    end

    context '本番環境で値が設定されている場合' do
      before { allow(Rails.env).to receive(:production?).and_return(true) }

      it 'raise しないこと' do
        expect { described_class.send(:validate_allowed_hostnames!, 'go-lilaregard.com') }
          .not_to raise_error
      end
    end

    context '本番環境以外で ENV が空の場合' do
      before { allow(Rails.env).to receive(:production?).and_return(false) }

      it 'raise しないこと (dev / test では空 list 許容)' do
        expect { described_class.send(:validate_allowed_hostnames!, '') }
          .not_to raise_error
      end
    end
  end
end
