# frozen_string_literal: true

# spec/requests/admins_spec.rb
require 'rails_helper'

RSpec.describe 'Admins' do
  describe '新規登録' do
    context 'メールアドレスのバリデーション' do
      it 'メールアドレスが必須である（空の場合は無効）' do
        admin = Admin.new(email: '', password: 'password123')
        expect(admin.valid?).to be false
      end

      it '正しいメールアドレスを入力すれば有効' do
        admin = Admin.new(email: 'test@example.com', password: 'password123')
        expect(admin.valid?).to be true
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
    end
  end
end
