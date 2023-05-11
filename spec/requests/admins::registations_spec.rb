# frozen_string_literal: true

require 'rails_helper'

RSpec.configure do |config|
  config.include Devise::Test::IntegrationHelpers, type: :request
end

RSpec.describe 'Admins::RegistrationsController', type: :request do
  describe '#one_user_registered?' do
    context '管理者が1人も存在しない場合' do
      it '何も行われない' do
        expect(Admin.count).to eq(0)
        get new_admin_session_url
        expect(response).to be_successful
      end
    end

    context '管理者が1人存在している場合' do
      let!(:admin) { FactoryBot.create(:admin) }

      context 'ログインしている場合' do
        before do
          sign_in admin
        end

        it 'root_pathにリダイレクトされる' do
          expect(Admin.count).to eq(1)
          get new_admin_session_url
          expect(response).to redirect_to(root_path)
        end
      end

      context 'ログインしていない場合' do
        it 'new_admin_session_pathにリダイレクトされる' do
          expect(Admin.count).to eq(1)
          get new_admin_session_url
        end
      end
    end
  end
end
