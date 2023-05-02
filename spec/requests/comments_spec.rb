# frozen_string_literal: true

require 'rails_helper'

# This spec was generated by rspec-rails when you ran the scaffold generator.
# It demonstrates how one might use RSpec to test the controller code that
# was generated by Rails when you ran the scaffold generator.
#
# It assumes that the implementation code is generated by the rails scaffold
# generator. If you are using any extension libraries to generate different
# controller code, this generated spec may or may not pass.
#
# It only uses APIs available in rails and/or rspec-rails. There are a number
# of tools you can use to make these specs even more expressive, but we're
# sticking to rails and rspec-rails APIs to keep things simple and stable.

RSpec.describe '/comments', type: :request do
  # This should return the minimal set of attributes required to create a valid
  # Comment. As you add validations to Comment, be sure to
  # adjust the attributes here as well.
  # let(:valid_attributes) do
  #   skip('Add a hash of attributes valid for your model')
  # end

  # let(:invalid_attributes) do
  #   skip('Add a hash of attributes invalid for your model')
  # end

  describe 'POST #create' do
    # before do
    #   @blog = FactoryBot.create(:blog)
    # end

    let!(:blog) { FactoryBot.create(:blog) }

    context 'コメントの属性値が有効な場合' do
      it 'コメントが作成されること' do
        expect do
          post blog_comments_path(blog), params: { comment: FactoryBot.attributes_for(:comment) }
        end.to change(Comment, :count).by(1)
      end

      it 'ブログ詳細ページにリダイレクトされること' do
        post blog_comments_path(blog), params: { comment: FactoryBot.attributes_for(:comment) }
        expect(response).to redirect_to(blog_url(blog))
      end
    end

    context 'コメントの属性値が無効な場合' do
      it '新規コメントページにリダイレクトされること' do
        expect do
          post blog_comments_path(blog), params: { comment: FactoryBot.attributes_for(:comment, other_user_name: '') }
        end.to change(Comment, :count).by(0)
      end

      it 'ブログの詳細ページにリダイレクトされること' do
        post blog_comments_path(blog), params: { comment: FactoryBot.attributes_for(:comment, other_user_name: '') }
        expect(response).to redirect_to(blog_url(blog))
      end

      it 'エラーメッセージが表示されること' do
        post blog_comments_path(blog), params: { comment: FactoryBot.attributes_for(:comment, other_user_name: '') }
        expect(flash[:notice]).to eq('Comment was not created.')
      end
    end
  end
end
