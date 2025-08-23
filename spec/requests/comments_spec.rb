# frozen_string_literal: true

require 'rails_helper'

RSpec.describe '/comments' do
  let!(:blog) { create(:blog) }

  describe 'POST #create' do
    context 'コメントの属性値が有効な場合' do
      it 'コメントが作成されること' do
        expect do
          post blog_comments_path(blog), params: { comment: attributes_for(:comment) }
        end.to change(Comment, :count).by(1)
      end

      it 'ブログ詳細ページにリダイレクトされること' do
        post blog_comments_path(blog), params: { comment: attributes_for(:comment) }
        expect(response).to redirect_to(blog_url(blog))
      end

      it '成功メッセージが表示されること' do
        post blog_comments_path(blog), params: { comment: attributes_for(:comment) }
        expect(flash[:notice]).to eq('コメントが作成されました。')
      end

      it 'コメントがブログに関連付けられること' do
        post blog_comments_path(blog), params: { comment: attributes_for(:comment) }
        expect(Comment.last.blog).to eq(blog)
      end
    end

    context 'コメントの属性値が無効な場合' do
      it 'コメントが作成されないこと' do
        expect do
          post blog_comments_path(blog), params: { comment: attributes_for(:comment, user_name: '') }
        end.not_to change(Comment, :count)
      end

      it 'ブログの詳細ページにリダイレクトされること' do
        post blog_comments_path(blog), params: { comment: attributes_for(:comment, user_name: '') }
        expect(response).to redirect_to(blog_url(blog))
      end

      it 'エラーメッセージが表示されること' do
        post blog_comments_path(blog), params: { comment: attributes_for(:comment, user_name: '') }
        expect(flash[:alert]).to eq('コメントが作成できませんでした。')
      end

      it 'user_nameが空白の場合もエラーになること' do
        expect do
          post blog_comments_path(blog), params: { comment: attributes_for(:comment, user_name: '   ') }
        end.not_to change(Comment, :count)
      end
    end

    context '存在しないblogに対してコメントする場合' do
      it 'ActiveRecord::RecordNotFoundが発生すること' do
        expect do
          post blog_comments_path(id: 999), params: { comment: attributes_for(:comment) }
        end.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context 'パラメータが不正な場合' do
      it 'commentパラメータが存在しない場合はエラーになること' do
        expect do
          post blog_comments_path(blog), params: {}
        end.to raise_error(ActionController::ParameterMissing)
      end
    end
  end
end
