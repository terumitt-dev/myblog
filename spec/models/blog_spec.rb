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
  end

  describe 'enum' do
    context 'カテゴリー' do
      it '正しいカテゴリーを持つこと' do
        expect(described_class.categories.keys).to match_array(%w[uncategorized hobby tech other])
      end
    end
  end
end
