# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Api::Auth', type: :request do
  before(:each) do
    JwtBlacklist.delete_all
    Admin.delete_all
  end

  describe 'POST /api/auth/sign_up' do
    context '正常なパラメータの場合' do
      let(:params) do
        {
          admin: {
            email: 'newadmin@example.com',
            password: 'password123',
            password_confirmation: 'password123'
          }
        }
      end

      it '成功レスポンスを返す' do
        post '/api/auth/sign_up', params: params, as: :json, headers: { 'Origin' => 'http://localhost:5173' }
        expect(response).to have_http_status(:created)
        expect(json_response['status']).to eq('success')
        expect(json_response['data']['email']).to eq('newadmin@example.com')
      end

      it 'sign_upではJWTトークンを返さない（sign_inで取得する設計）' do
        post '/api/auth/sign_up', params: params, as: :json, headers: { 'Origin' => 'http://localhost:5173' }
        expect(response.headers['Authorization']).to be_nil
      end
    end

    context '無効なパラメータの場合' do
      let(:params) do
        {
          admin: {
            email: 'invalid',
            password: 'password123',
            password_confirmation: 'password123'
          }
        }
      end

      before do
        Admin.delete_all
      end

      it 'エラーレスポンスを返す' do
        post '/api/auth/sign_up', params: params, as: :json, headers: { 'Origin' => 'http://localhost:5173' }
        expect(response).to have_http_status(:unprocessable_entity)
        expect(json_response['status']).to eq('error')
      end
    end
  end

  describe 'POST /api/auth/sign_in' do
    before(:each) do
      Admin.create!(email: 'admin@example.com', password: 'password123', password_confirmation: 'password123')
    end

    context '正常なメールアドレスとパスワードの場合' do
      it '成功レスポンスを返す' do
        post '/api/auth/sign_in',
             params: { admin: { email: 'admin@example.com', password: 'password123' } },
             as: :json,
             headers: { 'Origin' => 'http://localhost:5173' }
        expect(response).to have_http_status(:ok)
        expect(json_response['status']).to eq('success')
        expect(json_response['data']['email']).to eq('admin@example.com')
      end

      it 'Authorization ヘッダーにJWTトークンを返す' do
        post '/api/auth/sign_in',
             params: { admin: { email: 'admin@example.com', password: 'password123' } },
             as: :json,
             headers: { 'Origin' => 'http://localhost:5173' }
        expect(response.headers['Authorization']).to match(/^Bearer /)
      end
    end

    context '無効なメールアドレスの場合' do
      it 'エラーレスポンスを返す' do
        post '/api/auth/sign_in',
             params: { admin: { email: 'nonexistent@example.com', password: 'password123' } },
             as: :json,
             headers: { 'Origin' => 'http://localhost:5173' }
        expect(response).to have_http_status(:unauthorized)
        expect(json_response['status']).to eq('error')
      end
    end

    context '不正なOriginヘッダーの場合' do
      it 'CSRF保護により403 Forbiddenを返す' do
        post '/api/auth/sign_in',
             params: { admin: { email: 'admin@example.com', password: 'password123' } },
             headers: { 'Origin' => 'https://evil.com' },
             as: :json
        expect(response).to have_http_status(:forbidden)
        expect(json_response['status']).to eq('error')
        expect(json_response['message']).to eq('Origin not allowed')
      end
    end
  end

  describe 'DELETE /api/auth/sign_out' do
    before(:each) do
      Admin.create!(email: 'admin@example.com', password: 'password123', password_confirmation: 'password123')
    end

    let(:token) do
      post '/api/auth/sign_in',
           params: { admin: { email: 'admin@example.com', password: 'password123' } },
           as: :json,
           headers: { 'Origin' => 'http://localhost:5173' }
      response.headers['Authorization']
    end

    context '認証されている場合' do
      it '200を返す' do
        delete '/api/auth/sign_out',
               headers: { 'Authorization' => token, 'Origin' => 'http://localhost:5173' },
               as: :json
        expect(response).to have_http_status(:ok)
        expect(json_response['status']).to eq('success')
      end

      it 'ログアウト後、同じトークンでcurrent_userにアクセスできない（ブラックリスト登録）' do
        used_token = token

        delete '/api/auth/sign_out',
              headers: { 'Authorization' => used_token, 'Origin' => 'http://localhost:5173' },
              as: :json
        expect(response).to have_http_status(:ok)

        # ブラックリストに実際に登録されていることを確認
        expect(JwtBlacklist.count).to eq(1)

        get '/api/auth/current_user',
            headers: { 'Authorization' => used_token },
            as: :json
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context '認証されていない場合' do
      it 'Originなしで403 Forbiddenを返す' do
        delete '/api/auth/sign_out', as: :json
        expect(response).to have_http_status(:forbidden)
        expect(json_response['message']).to eq('Origin header required')
      end
    end
  end

  describe 'GET /api/auth/current_user' do
    before(:each) do
      Admin.create!(email: 'admin@example.com', password: 'password123', password_confirmation: 'password123')
    end

    let(:token) do
      post '/api/auth/sign_in',
           params: { admin: { email: 'admin@example.com', password: 'password123' } },
           as: :json,
           headers: { 'Origin' => 'http://localhost:5173' }
      response.headers['Authorization']
    end

    context '認証されている場合' do
      it '200を返し、ユーザー情報が含まれる' do
        get '/api/auth/current_user',
            headers: { 'Authorization' => token },
            as: :json
        expect(response).to have_http_status(:ok)
        expect(json_response['status']).to eq('success')
        expect(json_response['data']['email']).to eq('admin@example.com')
      end
    end

    context '認証されていない場合' do
      it '401 Unauthorized を返す' do
        get '/api/auth/current_user', as: :json
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  private

  def json_response
    JSON.parse(response.body)
  end
end
