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

    context 'Turnstile 検証が成功したがコメントが無効な場合' do
      before { allow(TurnstileService).to receive(:verify).and_return(true) }

      it 'コメントを作成せず comment の errors を含む 422 を返すこと' do
        expect do
          post "/api/blogs/#{blog.id}/comments",
               params: { comment: { user_name: '', comment: 'body' }, turnstile_token: 'good-token' }.to_json,
               headers: headers
        end.not_to change(Comment, :count)

        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.parsed_body['errors']).not_to be_empty
        # 認証エラーメッセージではないこと (Turnstile 通過後の comment validation エラー)
        expect(response.parsed_body['errors']).not_to include('認証に失敗しました。再度お試しください。')
      end
    end

    # request.remote_ip は XFF 偽装などで raise しうる (IpSpoofAttackError)。
    # safe_remote_ip ヘルパーが nil フォールバックする挙動を、コントローラ単体で検証する。
    # request spec で and_raise すると Rails::Rack::Logger も remote_ip を呼ぶため
    # middleware 段階で 500 になってしまい、コントローラ層の挙動を分離できない。
    describe '#safe_remote_ip (private)' do
      it 'request.remote_ip が StandardError を raise したら nil を返すこと' do
        controller = Api::CommentsController.new
        fake_request = instance_double(ActionDispatch::Request)
        allow(fake_request).to receive(:remote_ip)
          .and_raise(ActionDispatch::RemoteIp::IpSpoofAttackError, 'spoofed')
        allow(controller).to receive(:request).and_return(fake_request)

        expect(controller.send(:safe_remote_ip)).to be_nil
      end

      it '通常時は request.remote_ip の値を返すこと' do
        controller = Api::CommentsController.new
        fake_request = instance_double(ActionDispatch::Request, remote_ip: '203.0.113.10')
        allow(controller).to receive(:request).and_return(fake_request)

        expect(controller.send(:safe_remote_ip)).to eq('203.0.113.10')
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
