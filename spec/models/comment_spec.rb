# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Comment do
  let(:blog) { create(:blog) }

  describe 'validations' do
    it 'user_nameがない場合は無効であること' do
      comment = blog.comments.build(user_name: nil, comment: 'Test comment')
      expect(comment).not_to be_valid
    end

    it 'blogがない場合は無効であること' do
      comment = described_class.new(user_name: 'John', comment: 'Test comment')
      expect(comment).not_to be_valid
    end

    it 'commentフィールドがない場合でも有効であること' do
      comment = blog.comments.build(user_name: 'John', comment: nil)
      expect(comment).to be_valid
    end

    it '全ての必須項目がある場合は有効であること' do
      comment = blog.comments.build(user_name: 'John', comment: 'Test comment')
      expect(comment).to be_valid
    end

    it '空文字のuser_nameは無効であること' do
      comment = blog.comments.build(user_name: '', comment: 'Test comment')
      expect(comment).not_to be_valid
    end

    it 'user_nameが空白のみの場合は無効であること' do
      comment = blog.comments.build(user_name: '   ', comment: 'Test comment')
      expect(comment).not_to be_valid
    end
  end

  describe 'associations' do
    it 'Blogとのアソシエーション' do
      expect(described_class.reflect_on_association(:blog).macro).to eq :belongs_to
    end

    it 'blogが正しく関連付けられること' do
      comment = create(:comment, blog: blog)
      expect(comment.blog).to eq(blog)
    end

    it 'blogを通じてコメントにアクセスできること' do
      comment = create(:comment, blog: blog)
      expect(blog.comments).to include(comment)
    end
  end
end
