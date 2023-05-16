# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Admin, type: :model do
  describe 'validations' do
    it 'emailがない場合無効である' do
      admin = Admin.new(email: nil, password: 'password', password_confirmation: 'password')
      expect(admin).not_to be_valid
    end

    it 'passwordがない場合無効である' do
      admin = Admin.new(email: 'admin@example.com', password: nil, password_confirmation: nil)
      expect(admin).not_to be_valid
    end

    it '短すぎるpasswordの場合無効である' do
      admin = Admin.new(email: 'admin@example.com', password: 'short', password_confirmation: 'short')
      expect(admin).not_to be_valid
    end

    it '6文字以上のpasswordの場合有効である' do
      admin = Admin.new(email: 'admin@example.com', password: 'long_enough_password', password_confirmation: 'long_enough_password')
      expect(admin).to be_valid
    end
  end

  describe '#only_one_admin_allowed' do
    context '既に管理者が1人いる場合' do
      let!(:admin) { FactoryBot.create(:admin) }
  
      it 'エラーメッセージを追加する' do
        admin = Admin.new(email: 'demo@example.com', password: 'long_enough_password', password_confirmation: 'long_enough_password')
        admin.valid?
        expect(admin.errors[:base]).to include('Only one admin allowed')
      end
    end
  
    context '管理者が設定されていない場合' do
      it 'エラーメッセージを追加しない' do
        admin = Admin.new(email: 'test@example.com', password: 'long_enough_password', password_confirmation: 'long_enough_password')
        admin.valid?
        expect(admin.errors[:base]).to be_empty
      end
    end
  end
end
