# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Admins' do
  describe 'GET /admin' do
    context '未認証の場合' do
      it 'ルートページにリダイレクトされる' do
        get admin_root_path
        expect(response).to redirect_to(root_path)
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
        Admin.delete_all # 一意制約のためクリア
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
        Admin.delete_all # 一意制約のためクリア
        admin = Admin.new(email: 'test@example.com', password: 'password123')
        expect(admin.valid?).to be true
      end

      it '短すぎるパスワードは無効' do
        admin = Admin.new(email: 'test@example.com', password: '12345')
        expect(admin.valid?).to be false
      end
    end
  end
end
