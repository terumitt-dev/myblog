# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Admin, type: :model do
  describe 'validations' do
    it 'emailがない場合無効である' do
      admin = Admin.new(email: nil, password: 'password')
      expect(admin).not_to be_valid
    end

    it 'passwordがない場合無効である' do
      admin = Admin.new(email: 'admin@example.com', password: nil)
      expect(admin).not_to be_valid
    end

    it '短すぎるpasswordの場合無効である' do
      admin = Admin.new(email: 'admin@example.com', password: 'short')
      expect(admin).not_to be_valid
    end

    it '6文字以上のpasswordの場合有効である' do
      admin = Admin.new(email: 'admin@example.com', password: 'long_enough_password')
      expect(admin).to be_valid
    end
  end
end
