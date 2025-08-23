# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'routing to comments' do
  it 'routes GET /blogs/:blog_id/comments to comments#index' do
    expect(get: '/blogs/1/comments').to route_to(controller: 'comments', action: 'index', blog_id: '1')
  end

  it 'routes GET /blogs/:blog_id/comments/new to comments#new' do
    expect(get: '/blogs/1/comments/new').to route_to(controller: 'comments', action: 'new', blog_id: '1')
  end

  it 'routes GET /blogs/:blog_id/comments/:id to comments#show' do
    expect(get: '/blogs/1/comments/1').to route_to(controller: 'comments', action: 'show', blog_id: '1', id: '1')
  end

  it 'routes GET /blogs/:blog_id/comments/:id/edit to comments#edit' do
    expect(get: '/blogs/1/comments/1/edit').to route_to(controller: 'comments', action: 'edit', blog_id: '1', id: '1')
  end

  it 'routes POST /blogs/:blog_id/comments to comments#create' do
    expect(post: '/blogs/1/comments').to route_to(controller: 'comments', action: 'create', blog_id: '1')
  end

  it 'routes PUT /blogs/:blog_id/comments/:id to comments#update' do
    expect(put: '/blogs/1/comments/1').to route_to(controller: 'comments', action: 'update', blog_id: '1', id: '1')
  end

  it 'routes PATCH /blogs/:blog_id/comments/:id to comments#update' do
    expect(patch: '/blogs/1/comments/1').to route_to(controller: 'comments', action: 'update', blog_id: '1', id: '1')
  end

  it 'routes DELETE /blogs/:blog_id/comments/:id to comments#destroy' do
    expect(delete: '/blogs/1/comments/1').to route_to(controller: 'comments', action: 'destroy', blog_id: '1', id: '1')
  end
end
