# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Blog, type: :model do
  describe 'validations' do
    context 'titleが空の場合' do
      it '無効であること' do
        blog = Blog.new(title: nil)
        expect(blog).to_not be_valid
      end
    end

    context 'categoryが空の場合' do
      it '無効であること' do
        blog = Blog.new(category: nil)
        expect(blog).to_not be_valid
      end
    end

    context 'contentが空の場合' do
      it '無効であること' do
        blog = Blog.new(content: nil)
        expect(blog).to_not be_valid
      end
    end
  end

  describe 'enum' do
    context 'カテゴリー' do
      it '正しいカテゴリーを持つこと' do
        expect(Blog.categories.keys).to match_array(%w[uncategorized hobby tech other])
      end
    end
  end
end
