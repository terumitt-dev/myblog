# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Api::Auth', type: :request do
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
        post '/api/auth/sign_up', params: params, as: :json
        expect(response).to have_http_status(:created)
        expect(json_response['status']).to eq('success')
        expect(json_response['data']['email']).to eq('newadmin@example.com')
      end

      it 'Authorization ヘッダーにJWTトークンを返す' do
        post '/api/auth/sign_up', params: params, as: :json
        expect(response.headers['Authorization']).to match(/^Bearer /)
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

      it 'エラーレスポンスを返す' do
        post '/api/auth/sign_up', params: params, as: :json
        expect(response).to have_http_status(:unprocessable_entity)
        expect(json_response['status']).to eq('error')
      end
    end
  end

  describe 'POST /api/auth/sign_in' do
    context '正常なメールアドレスとパスワードの場合' do
      let(:params) do
        {
          admin: {
            email: 'admin@example.com',
            password: 'password123'
          }
        }
      end

      before do
        Admin.delete_all
        create(:admin, email: 'admin@example.com', password: 'password123')
      end

      it '成功レスポンスを返す' do
        post '/api/auth/sign_in', params: params, as: :json
        expect(response).to have_http_status(:ok)
        expect(json_response['status']).to eq('success')
        expect(json_response['data']['email']).to eq('admin@example.com')
      end

      it 'Authorization ヘッダーにJWTトークンを返す' do
        post '/api/auth/sign_in', params: params, as: :json
        expect(response.headers['Authorization']).to match(/^Bearer /)
      end
    end

    context '無効なメールアドレスの場合' do
      let(:params) do
        {
          admin: {
            email: 'nonexistent@example.com',
            password: 'password123'
          }
        }
      end

      it 'エラーレスポンスを返す' do
        post '/api/auth/sign_in', params: params, as: :json
        expect(response).to have_http_status(:unauthorized)
        expect(json_response['status']).to eq('error')
      end
    end

    context '不正なOriginヘッダーの場合' do
      let(:params) do
        {
          admin: {
            email: 'admin@example.com',
            password: 'password123'
          }
        }
      end

      before do
        Admin.delete_all
        create(:admin, email: 'admin@example.com', password: 'password123')
      end

      it 'CSRF保護により403 Forbiddenを返す' do
        post '/api/auth/sign_in', params: params, as: :json, headers: { 'Origin' => 'https://evil.com' }
        expect(response).to have_http_status(:forbidden)
        expect(json_response['status']).to eq('error')
        expect(json_response['message']).to eq('Origin not allowed')
      end
    end
  end

  describe 'DELETE /api/auth/sign_out' do
    context '認証されていない場合' do
      it '401 Unauthorized を返す' do
        delete '/api/auth/sign_out', as: :json
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe 'GET /api/auth/current_user' do
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
