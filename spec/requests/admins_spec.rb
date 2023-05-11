# frozen_string_literal: true

require 'rails_helper'

RSpec.configure do |config|
  config.include Devise::Test::IntegrationHelpers, type: :request
end

RSpec.describe 'Admins', type: :request do
  describe '管理者のリクエスト' do
    let!(:admin) { FactoryBot.create(:admin) }
    context 'ログインしている場合' do
      before do
        sign_in admin
      end

      it 'indexテンプレートを表示する' do
        get admin_root_url
        expect(response).to be_successful
      end
    end

    let(:admin) { build(:admin, email: nil, password: nil) }
    context 'ログイン情報が未入力の場合' do
      before do
        sign_in admin
      end

      it 'ログインページに回帰する' do
        get new_admin_session_url
      end
    end
  end
end
