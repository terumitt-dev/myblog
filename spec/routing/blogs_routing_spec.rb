# frozen_string_literal: true

require 'rails_helper'

RSpec.configure do |config|
  config.include Devise::Test::IntegrationHelpers, type: :routing
end

RSpec.describe 'routes for blogs', type: :routing do
  context '管理者ユーザーの場合' do
    let!(:admin) { FactoryBot.create(:admin) }
    before do
      sign_in admin

      it 'routes to #index' do
        expect(get: '/blogs').to route_to('blogs#index')
      end
    
      it 'routes to #new' do
        expect(get: '/blogs/new').to route_to('blogs#new')
      end
    
      it 'routes to #show' do
        expect(get: '/blogs/1').to route_to('blogs#show', id: '1')
      end
    
      it 'routes to #edit' do
        expect(get: '/blogs/1/edit').to route_to('blogs#edit', id: '1')
      end
    
      it 'routes to #create' do
        expect(post: '/blogs').to route_to('blogs#create')
      end
    
      it 'routes to #update via PUT' do
        expect(put: '/blogs/1').to route_to('blogs#update', id: '1')
      end
    
      it 'routes to #update via PATCH' do
        expect(patch: '/blogs/1').to route_to('blogs#update', id: '1')
      end
    
      it 'routes to #destroy' do
        expect(delete: '/blogs/1').to route_to('blogs#destroy', id: '1')
      end
    end
  end
end
