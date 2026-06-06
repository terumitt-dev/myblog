# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Api::Blogs::Comments', type: :request do
  let(:blog) { create(:blog) }
  let(:headers) { { 'Content-Type' => 'application/json' } }
  let(:valid_comment_params) { { user_name: 'taro', comment: 'good post!' } }

  describe 'POST /api/blogs/:blog_id/comments' do
    context 'Turnstile 検証が成功した場合' do
      before { allow(TurnstileService).to receive(:verify).and_return(true) }

      it 'コメントを作成して 201 を返すこと' do
        expect do
          post "/api/blogs/#{blog.id}/comments",
               params: { comment: valid_comment_params, turnstile_token: 'good-token' }.to_json,
               headers: headers
        end.to change(Comment, :count).by(1)

        expect(response).to have_http_status(:created)
        body = response.parsed_body
        expect(body['user_name']).to eq('taro')
        expect(body['comment']).to eq('good post!')
      end

      it 'Turnstile.verify に token と remote_ip を渡すこと' do
        expect(TurnstileService).to receive(:verify)
          .with('good-token', remote_ip: kind_of(String))
          .and_return(true)

        post "/api/blogs/#{blog.id}/comments",
             params: { comment: valid_comment_params, turnstile_token: 'good-token' }.to_json,
             headers: headers
      end
    end

    context 'Turnstile 検証が失敗した場合' do
      before { allow(TurnstileService).to receive(:verify).and_return(false) }

      it 'コメントを作成せず 422 を返すこと' do
        expect do
          post "/api/blogs/#{blog.id}/comments",
               params: { comment: valid_comment_params, turnstile_token: 'bad-token' }.to_json,
               headers: headers
        end.not_to change(Comment, :count)

        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.parsed_body['errors']).to include('認証に失敗しました。再度お試しください。')
      end

      it 'token が空でも 422 を返すこと' do
        post "/api/blogs/#{blog.id}/comments",
             params: { comment: valid_comment_params, turnstile_token: '' }.to_json,
             headers: headers

        expect(response).to have_http_status(:unprocessable_entity)
      end

      it 'token が未送信でも 422 を返すこと' do
        post "/api/blogs/#{blog.id}/comments",
             params: { comment: valid_comment_params }.to_json,
             headers: headers

        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    context 'Blog が存在しない場合' do
      before { allow(TurnstileService).to receive(:verify).and_return(true) }

      it '404 を返すこと' do
        post '/api/blogs/0/comments',
             params: { comment: valid_comment_params, turnstile_token: 'good-token' }.to_json,
             headers: headers

        expect(response).to have_http_status(:not_found)
      end
    end
  end
end
