# frozen_string_literal: true

require 'rails_helper'

# パスワードリセット HTTP 経路のリクエストスペック。
# rescue StandardError で握り潰される silent failure 系バグの回帰を CI で検出する目的。
# 実際 2026-05-04 に Api::Admin namespace 衝突 (Admin -> ::Admin) の silent failure が
# ローカル smoke test で初めて発見されたため、その種のバグを今後 CI で防ぐためのスペック。
RSpec.describe 'Api::Auth::Passwords', type: :request do
  # rails_helper.rb で 'test-password-reset-secret' が ENV に default で入っている前提。
  let(:valid_secret) { ENV.fetch('PASSWORD_RESET_SECRET') }
  let(:json_headers) { { 'Content-Type' => 'application/json' } }

  before(:each) do
    JwtBlacklist.delete_all
    ::Admin.delete_all
    ActiveJob::Base.queue_adapter = :test
    ActiveJob::Base.queue_adapter.enqueued_jobs.clear
    ActiveJob::Base.queue_adapter.performed_jobs.clear
  end

  describe 'POST /api/auth/password' do
    let!(:admin) do
      ::Admin.create!(
        email: 'admin@example.com',
        password: 'oldpassword123',
        password_confirmation: 'oldpassword123'
      )
    end

    context 'valid secret' do
      it 'returns 202 and enqueues PasswordResetRequestJob with send_reset:true' do
        post '/api/auth/password', params: { secret: valid_secret }.to_json, headers: json_headers

        expect(response).to have_http_status(:accepted)
        expect(PasswordResetRequestJob).to have_been_enqueued.with(admin_id: admin.id, send_reset: true)
      end

      it 'actually sets reset_password_token when the enqueued job runs (integration)' do
        # ジョブ実行までやって DB に token が反映されることを確認。
        # これが今回の Api::Admin namespace 衝突 silent failure を直接検出するスペック。
        perform_enqueued_jobs do
          post '/api/auth/password', params: { secret: valid_secret }.to_json, headers: json_headers
        end

        expect(response).to have_http_status(:accepted)
        expect(admin.reload.reset_password_token).to be_present
        expect(admin.reload.reset_password_sent_at).to be_present
      end
    end

    context 'invalid secret' do
      it 'returns 202 and enqueues a no-op job (send_reset:false)' do
        post '/api/auth/password', params: { secret: 'wrong-secret' }.to_json, headers: json_headers

        expect(response).to have_http_status(:accepted)
        expect(PasswordResetRequestJob).to have_been_enqueued.with(admin_id: admin.id, send_reset: false)
      end

      it 'does not set reset_password_token even after job runs' do
        perform_enqueued_jobs do
          post '/api/auth/password', params: { secret: 'wrong-secret' }.to_json, headers: json_headers
        end

        expect(response).to have_http_status(:accepted)
        expect(admin.reload.reset_password_token).to be_nil
      end
    end

    context 'missing secret (params not provided)' do
      it 'returns 202 (response code uniformity)' do
        post '/api/auth/password', params: {}.to_json, headers: json_headers
        expect(response).to have_http_status(:accepted)
      end
    end

    context 'malformed JSON body' do
      it 'returns 202 (response code uniformity, never 500)' do
        post '/api/auth/password', params: 'not-json', headers: json_headers
        expect(response).to have_http_status(:accepted)
      end
    end

    context 'when no admin exists' do
      before { ::Admin.delete_all }

      it 'returns 202 with admin_id:nil and send_reset:false' do
        post '/api/auth/password', params: { secret: valid_secret }.to_json, headers: json_headers

        expect(response).to have_http_status(:accepted)
        expect(PasswordResetRequestJob).to have_been_enqueued.with(admin_id: nil, send_reset: false)
      end
    end
  end

  describe 'PATCH /api/auth/password' do
    let!(:admin) do
      ::Admin.create!(
        email: 'admin@example.com',
        password: 'oldpassword123',
        password_confirmation: 'oldpassword123'
      )
    end

    let(:raw_token) do
      raw, hashed = Devise.token_generator.generate(::Admin, :reset_password_token)
      admin.update_columns(reset_password_token: hashed, reset_password_sent_at: Time.current)
      raw
    end

    context 'with valid token and matching password' do
      it 'returns 200 and updates the password' do
        patch '/api/auth/password',
              params: {
                reset_password_token: raw_token,
                password: 'newpassword456',
                password_confirmation: 'newpassword456'
              }.to_json,
              headers: json_headers

        expect(response).to have_http_status(:ok)
        expect(admin.reload.valid_password?('newpassword456')).to be true
      end
    end

    context 'with invalid token' do
      it 'returns 401' do
        patch '/api/auth/password',
              params: {
                reset_password_token: 'badtoken',
                password: 'newpassword456',
                password_confirmation: 'newpassword456'
              }.to_json,
              headers: json_headers

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'with valid token but password mismatch' do
      it 'returns 422' do
        patch '/api/auth/password',
              params: {
                reset_password_token: raw_token,
                password: 'newpassword456',
                password_confirmation: 'DIFFERENT'
              }.to_json,
              headers: json_headers

        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    context 'with malformed JSON body' do
      it 'returns 401 (空ハッシュフォールバックで token 不在として扱われる)' do
        patch '/api/auth/password', params: 'not-json', headers: json_headers
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when no admin exists (singleton broken: 0 admins)' do
      before { ::Admin.delete_all }

      it 'returns 401 (admin count guard)' do
        patch '/api/auth/password',
              params: {
                reset_password_token: 'anytoken',
                password: 'newpassword456',
                password_confirmation: 'newpassword456'
              }.to_json,
              headers: json_headers

        expect(response).to have_http_status(:unauthorized)
      end
    end
  end
end
