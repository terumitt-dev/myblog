# frozen_string_literal: true

require 'rails_helper'

RSpec.configure do |config|
  config.include Devise::Test::IntegrationHelpers, type: :request
end

RSpec.describe 'Admins' do
  let(:admin) { create(:admin) }

  describe 'GET /admin' do
    context '認証済み管理者の場合' do
      before { sign_in admin }

      it 'admin indexページが表示される' do
        get admin_root_path
        expect(response).to be_successful
      end

      it '@blogsが設定される' do
        blog = create(:blog)
        get admin_root_path
        expect(assigns(:blogs)).to include(blog)
      end

      it '@blogが新規作成用に設定される' do
        get admin_root_path
        expect(assigns(:blog)).to be_a_new(Blog)
      end

      it '複数のブログが@blogsに含まれる' do
        blog1 = create(:blog, title: 'First Blog')
        blog2 = create(:blog, title: 'Second Blog')
        get admin_root_path
        expect(assigns(:blogs)).to contain_exactly(blog1, blog2)
      end
    end

    context '未認証の場合' do
      it 'ログインページにリダイレクトされる' do
        get admin_root_path
        expect(response).to redirect_to(new_admin_session_path)
      end
    end
  end

  describe 'Admin モデルのバリデーション' do
    context 'メールアドレスのバリデーション' do
      it 'メールアドレスが必須である（空の場合は無効）' do
        admin = Admin.new(email: '', password: 'password123')
        expect(admin.valid?).to be false
      end

      it '正しいメールアドレスを入力すれば有効' do
        admin = Admin.new(email: 'test@example.com', password: 'password123')
        expect(admin.valid?).to be true
      end

      it '不正な形式のメールアドレスは無効' do
        admin = Admin.new(email: 'invalid-email', password: 'password123')
        expect(admin.valid?).to be false
      end
    end

    context 'パスワードのバリデーション' do
      it 'パスワードが必須である（空の場合は無効）' do
        admin = Admin.new(email: 'test@example.com', password: '')
        expect(admin.valid?).to be false
      end

      it 'パスワードを入力すれば有効' do
        admin = Admin.new(email: 'test@example.com', password: 'password123')
        expect(admin.valid?).to be true
      end

      it '短すぎるパスワードは無効' do
        admin = Admin.new(email: 'test@example.com', password: '12345')
        expect(admin.valid?).to be false
      end
    end

    context '管理者の一意制約' do
      it '既存の管理者がいる場合、新規作成は失敗する' do
        create(:admin)
        new_admin = Admin.new(email: 'new@example.com', password: 'password123')
        expect(new_admin.valid?).to be false
      end

      it '既存の管理者がいる場合、適切なエラーメッセージが表示される' do
        create(:admin)
        new_admin = Admin.new(email: 'new@example.com', password: 'password123')
        new_admin.valid?
        expect(new_admin.errors[:base]).to include('Only one admin allowed')
      end
    end
  end
end
