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

  describe '.import_from_mt' do
    it '正しいMTファイルでブログが作成されること' do
      temp_file = Tempfile.new(['sample', '.txt'])
      temp_file.write("AUTHOR: test\nTITLE: サンプルブログ\nDATE: 12/17/2024 19:00:00\nBODY:\n本文です\n-----\n")
      temp_file.rewind

      expect(Blog.valid_mt_file?(temp_file)).to be true

      expect {
        Blog.import_from_mt(temp_file)
      }.to change(Blog, :count).by(1)

      blog = Blog.last
      expect(blog.title).to eq 'サンプルブログ'
      expect(blog.content).to eq '本文です'

      temp_file.close
      temp_file.unlink
    end

    it '無効なMTファイルではブログが作成されないこと' do
      temp_file = Tempfile.new(['invalid', '.txt'])
      temp_file.write("無効な内容")
      temp_file.rewind

      expect {
        Blog.import_from_mt(temp_file)
      }.to_not change(Blog, :count)

      temp_file.close
      temp_file.unlink
    end
  end
end
