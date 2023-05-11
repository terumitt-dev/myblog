# frozen_string_literal: true

require 'rails_helper'

RSpec.configure do |config|
  config.include Devise::Test::IntegrationHelpers, type: :routing
end

RSpec.describe '管理者ページへのアクセスルート', type: :routing do
  let!(:admin) { FactoryBot.create(:admin) }
  context '管理者ユーザーの場合' do
    before do
      sign_in admin

      it 'routes to #index' do
        expect(get: '/asmin_root').to route_to('admins#index')
      end
    end
  end

  let(:admin) { build(:admin, email: nil, password: nil) }
  context '一般ユーザーの場合' do
    before do
      sign_in admin
      it 'routes to #index' do
        expect(get: '/asmin_root').not_to route_to('admins#index')
      end
    end
  end
end   
