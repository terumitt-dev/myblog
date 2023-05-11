# frozen_string_literal: true

require 'rails_helper'

RSpec.configure do |config|
  config.include Devise::Test::IntegrationHelpers, type: :request
end

RSpec.describe 'Admins', type: :request do
  context 'ログインしている場合' do
    let!(:admin) { FactoryBot.create(:admin) }
    before do
      sign_in admin
    end
    
    it 'indexテンプレートを表示する' do
      get admin_root_url
      expect(response).to be_successful
    end
  end
    
  context 'ログインしていない場合' do
    let(:admin) { build(:admin, email: nil, password: nil) }
    before do
      sign_in admin
    end

    it 'ログインページに回帰する' do
      get new_admin_session_url
    end
  end
end
