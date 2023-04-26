# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Blog, type: :model do
  describe 'validations' do
    it 'titleがない場合は無効であること' do
      blog = Blog.new(title: nil)
      expect(blog).to_not be_valid
    end

    it 'categoryがない場合は無効であること' do
      blog = Blog.new(category: nil)
      expect(blog).to_not be_valid
    end

    it 'contentがない場合は無効であること' do
      blog = Blog.new(content: nil)
      expect(blog).to_not be_valid
    end
  end
end

RSpec.describe Blog, type: :model do
  describe 'enum' do
    it '正しいカテゴリーを持つか' do
      expect(Blog.categories.keys).to match_array(%w[uncategorized hobby tech other])
    end
  end
end
