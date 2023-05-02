# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Comment, type: :model do
  it 'other_user_nameがない場合は無効であること' do
    comment = Comment.new(other_user_name: nil)
    expect(comment).not_to be_valid
  end

  it 'blog_idがない場合は無効であること' do
    comment = Comment.new(blog_id: nil)
    expect(comment).not_to be_valid
  end

  it 'blog_idとother_user_nameがある場合は有効であること' do
    blog = Blog.create(title: 'test', content: 'test')
    comment = blog.comments.create(other_user_name: 'test')
    expect(comment).to be_valid
  end
end
