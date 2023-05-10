# frozen_string_literal: true

require 'rails_helper'

RSpec.configure do |config|
  config.include Devise::Test::IntegrationHelpers, type: :request
end

RSpec.describe 'Admins', type: :request do
  describe 'GET /index' do
    context 'ログイン済みの場合' do
      let!(:admin) { FactoryBot.create(:admin) }
      let!(:blog) { FactoryBot.create(:blog) }

      before do
        sign_in admin
      end
    
      it 'indexテンプレートを表示すること' do
        get admin_root_url
        expect(response).to be_successful
      end
    
      it 'assigns @blogs' do
        get admin_root_url
        expect(assigns(:blogs)).to eq([blog])
      end
    
      it 'assigns @blog' do
        get admin_root_url
        expect(assigns(:blog)).to be_a_new(Blog)
      end
    end
  end
end
