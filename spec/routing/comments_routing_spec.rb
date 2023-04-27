# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CommentsController, type: :routing do
  describe 'routing' do
    it 'routes to #index' do
      expect(get: '/blogs/:blog_id/comments').to route_to('comments#index')
    end

    it 'routes to #new' do
      expect(get: '/blogs/1/comments/new').to route_to('comments#new')
    end

    it 'routes to #show' do
      expect(get: '/blogs/1/comments/1').to route_to('comments#show', id: '1')
    end

    it 'routes to #edit' do
      expect(get: '/blogs/1/comments/1/edit').to route_to('comments#edit', id: '1')
    end

    it 'routes to #create' do
      expect(post: '/blogs/1/comments').to route_to('comments#create')
    end

    it 'routes to #update via PUT' do
      expect(put: '/blogs/1/comments/1').to route_to('comments#update', id: '1')
    end

    it 'routes to #update via PATCH' do
      expect(patch: '/blogs/1/comments/1').to route_to('comments#update', id: '1')
    end

    it 'routes to #destroy' do
      expect(delete: '/blogs/1/comments/1').to route_to('comments#destroy', id: '1')
    end
  end
end
