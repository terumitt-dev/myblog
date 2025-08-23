# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Admin do
  describe 'validations' do
    it 'emailがない場合無効である' do
      admin = described_class.new(email: nil, password: 'password', password_confirmation: 'password')
      expect(admin).not_to be_valid
    end

    it 'passwordがない場合無効である' do
      admin = described_class.new(email: 'admin@example.com', password: nil, password_confirmation: nil)
      expect(admin).not_to be_valid
    end

    it '短すぎるpasswordの場合無効である' do
      admin = described_class.new(email: 'admin@example.com', password: 'short', password_confirmation: 'short')
      expect(admin).not_to be_valid
    end

    it '6文字以上のpasswordの場合有効である' do
      admin = described_class.new(email: 'admin@example.com', password: 'long_enough_password',
                                  password_confirmation: 'long_enough_password')
      expect(admin).to be_valid
    end

    it '不正な形式のメールアドレスは無効である' do
      admin = described_class.new(email: 'invalid-email', password: 'password123', password_confirmation: 'password123')
      expect(admin).not_to be_valid
    end

    it '重複したメールアドレスは無効である' do
      create(:admin, email: 'test@example.com')
      admin = described_class.new(email: 'test@example.com', password: 'password123',
                                  password_confirmation: 'password123')
      expect(admin).not_to be_valid
    end
  end

  describe '#only_one_admin_allowed' do
    context '既に管理者が1人いる場合' do
      let!(:existing_admin) { create(:admin) }

      it '新規管理者にエラーを追加する' do
        admin = described_class.new(email: 'demo@example.com', password: 'long_enough_password',
                                    password_confirmation: 'long_enough_password')
        admin.valid?
        expect(admin.errors[:base]).to include('Only one admin allowed')
      end

      it '既存管理者は新しいパスワードで有効かつ保存できる', :aggregate_failures do
        existing_admin.password = 'new_secure_password'
        existing_admin.password_confirmation = 'new_secure_password'
        expect(existing_admin).to be_valid
        expect(existing_admin.save).to be true
      end
    end

    context '管理者が設定されていない場合' do
      it 'エラーメッセージを追加しない' do
        admin = described_class.new(email: 'test@example.com', password: 'long_enough_password',
                                    password_confirmation: 'long_enough_password')
        admin.valid?
        expect(admin.errors[:base]).to be_empty
      end
    end
  end

  describe 'Devise modules' do
    it 'database_authenticatable モジュールが含まれている' do
      expect(described_class.devise_modules).to include(:database_authenticatable)
    end

    it 'registerable モジュールが含まれている' do
      expect(described_class.devise_modules).to include(:registerable)
    end
  end
end
