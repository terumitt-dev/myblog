# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Blog do
  describe 'validations' do
    context 'titleが空の場合' do
      it '無効であること' do
        blog = described_class.new(title: nil)
        expect(blog).not_to be_valid
      end
    end

    context 'categoryが空の場合' do
      it '無効であること' do
        blog = described_class.new(category: nil)
        expect(blog).not_to be_valid
      end
    end

    context 'contentが空の場合' do
      it '無効であること' do
        blog = described_class.new(content: nil)
        expect(blog).not_to be_valid
      end
    end

    context '全ての必須項目がある場合' do
      it '有効であること' do
        blog = described_class.new(title: 'Test Title', category: 'hobby', content: 'Test Content')
        expect(blog).to be_valid
      end
    end
  end

  describe 'associations' do
    it 'has many comments' do
      expect(described_class.reflect_on_association(:comments).macro).to eq :has_many
    end

    it 'destroys associated comments when deleted' do
      blog = create(:blog)
      create(:comment, blog: blog)
      expect { blog.destroy }.to change(Comment, :count).by(-1)
    end

    it '複数のコメントを持つことができる' do
      blog = create(:blog)
      comment1 = create(:comment, blog: blog, user_name: 'User1')
      comment2 = create(:comment, blog: blog, user_name: 'User2')
      expect(blog.comments).to contain_exactly(comment1, comment2)
    end
  end

  describe 'enum' do
    context 'カテゴリー' do
      it '正しいカテゴリーを持つこと' do
        expect(described_class.categories.keys).to match_array(%w[uncategorized hobby tech other])
      end

      it 'デフォルトカテゴリーがuncategorizedであること' do
        blog = described_class.new
        expect(blog.category).to eq 'uncategorized'
      end
    end
  end
end
