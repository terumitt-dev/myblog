# frozen_string_literal: true

require 'rails_helper'

RSpec.configure do |config|
  config.include Devise::Test::IntegrationHelpers, type: :request
end

RSpec.describe 'Blogs' do
  let(:admin) { create(:admin) }
  let(:blog) { create(:blog) }

  describe '管理者ユーザーの場合' do
    before { sign_in admin }

    it '投稿一覧ページが出力される' do
      blog
      get blogs_url
      expect(response).to be_successful
    end

    it '新規投稿ページが出力される' do
      get new_blog_url
      expect(response).to be_successful
    end

    it '編集ページが出力される' do
      blog
      get edit_blog_url(blog)
      expect(response).to be_successful
    end

    context 'POST /create' do
      it '正しいパラメータで投稿が作成される' do
        valid_params = { blog: { title: 'Test Blog', category: 'hobby', content: 'Lorem ipsum' } }
        expect { post blogs_url, params: valid_params }.to change(Blog, :count).by(1)
      end

      it '正しいパラメータで投稿後にリダイレクトされる' do
        valid_params = { blog: { title: 'Test Blog', category: 'hobby', content: 'Lorem ipsum' } }
        post blogs_url, params: valid_params
        expect(response).to redirect_to(blog_url(Blog.last))
      end

      it '無効なパラメータでは投稿は作成されない' do
        invalid_params = { blog: { title: '', category: 'hobby', content: 'Lorem ipsum' } }
        expect { post blogs_url, params: invalid_params }.not_to change(Blog, :count)
      end

      it '無効なパラメータでは422を返す' do
        invalid_params = { blog: { title: '', category: 'hobby', content: 'Lorem ipsum' } }
        post blogs_url, params: invalid_params
        expect(response).to have_http_status(:unprocessable_content)
      end
    end

    context 'PATCH /update' do
      it '有効なパラメータでタイトルが更新される' do
        patch blog_url(blog), params: { blog: { title: 'Updated Blog' } }
        expect(blog.reload.title).to eq 'Updated Blog'
      end

      it '有効なパラメータでカテゴリが更新される' do
        patch blog_url(blog), params: { blog: { category: 'other' } }
        expect(blog.reload.category).to eq 'other'
      end

      it '有効なパラメータでコンテンツが更新される' do
        patch blog_url(blog), params: { blog: { content: 'Lorem ipsum2' } }
        expect(blog.reload.content).to eq 'Lorem ipsum2'
      end

      it '有効なパラメータで更新後にリダイレクトされる' do
        patch blog_url(blog), params: { blog: { title: 'Updated Blog', category: 'other', content: 'Lorem ipsum2' } }
        expect(response).to redirect_to(blog_url(blog))
      end

      it '無効なパラメータで更新すると422を返す' do
        patch blog_url(blog), params: { blog: { title: '' } }
        expect(response).to have_http_status(:unprocessable_content)
      end
    end

    context 'DELETE /destroy' do
      it '投稿が削除される' do
        blog
        expect { delete blog_url(blog) }.to change(Blog, :count).by(-1)
      end

      it '削除後に一覧ページにリダイレクトされる' do
        delete blog_url(blog)
        expect(response).to redirect_to(admin_root_url)
      end
    end
  end

  describe '一般ユーザーの場合' do
    it '投稿一覧ページが出力される' do
      blog
      get blogs_url
      expect(response).to be_successful
    end

    it '投稿詳細ページが出力される' do
      blog
      get blog_url(blog)
      expect(response).to be_successful
    end
  end
end
