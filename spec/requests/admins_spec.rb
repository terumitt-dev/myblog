# frozen_string_literal: true

require 'rails_helper'

RSpec.configure do |config|
  config.include Devise::Test::IntegrationHelpers, type: :request
end

RSpec.describe 'Admins', type: :request do
  describe 'GET /index' do
    context 'ログインしている場合' do
      let!(:admin) { FactoryBot.create(:admin) }
      let!(:blog) { FactoryBot.create(:blog) }

      before do
        sign_in admin
      end
    
      it 'indexテンプレートを表示すること' do
        get admin_root_url
        expect(response).to be_successful
        expect(response.body).to include(blog.title)
        expect(response.body).to include(blog.content)
      end
    
      it '@blogsに全てのブログが割り当てられていること' do
        blog = assigns(:blog)
        expect(blog).to be_a(Blog)
        expect(blog.persisted?).to be false
      end

      it '@blogに新しいBlogが割り当てられていること' do
        expect(assigns(:blog)).to be_a_new(Blog)
      end

      it 'indexテンプレートをレンダリングすること' do
        expect(response).to render_template(:index)
      end
    end

    context 'ログインしていない場合' do
      it 'ログインページにリダイレクトすること' do
        get admin_root_url
        expect(response).to redirect_to(new_admin_session_path)
      end
    end
  end
end
