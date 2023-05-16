# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Comment, type: :model do
  describe 'validations' do
    let(:blog) { Blog.create(title: 'Test', category: :hobby, content: 'test content') }

    it 'user_nameがない場合は無効であること' do
      comment = blog.comments.build(user_name: nil)
      expect(comment).to_not be_valid
    end

    it 'blogがない場合は無効であること' do
      comment = Comment.new(user_name: 'John')
      expect(comment).to_not be_valid
    end
  end

  describe 'associations' do
    it 'Blogとのアソシエーション' do
      expect(Comment.reflect_on_association(:blog).macro).to eq :belongs_to
    end
  end
end
