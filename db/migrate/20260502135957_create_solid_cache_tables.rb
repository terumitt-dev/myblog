# frozen_string_literal: true

# SolidCache (Rails.cache 永続化バックエンド) 用のテーブルを main DB に作成する。
# 公式ジェネレータは separate DB (cache 接続) を前提に db/cache_schema.rb を
# 生成するが、SolidQueue と同様に個人ブログ規模では同一 DB に統合する方がシンプル。
# テーブル定義は solid_cache 1.0.10 の db/cache_schema.rb から転記。
#
# 用途: Rack::Attack のレート制限カウンタを共有キャッシュに乗せて、
# 複数 Puma worker / 複数 Pod 構成でも全体スロットリングを正しく機能させる。
class CreateSolidCacheTables < ActiveRecord::Migration[8.0]
  def change
    create_table 'solid_cache_entries' do |t|
      t.binary 'key', limit: 1024, null: false
      t.binary 'value', limit: 536_870_912, null: false
      t.datetime 'created_at', null: false
      t.integer 'key_hash', limit: 8, null: false
      t.integer 'byte_size', limit: 4, null: false
      t.index ['byte_size'], name: 'index_solid_cache_entries_on_byte_size'
      t.index %w[key_hash byte_size], name: 'index_solid_cache_entries_on_key_hash_and_byte_size'
      t.index ['key_hash'], name: 'index_solid_cache_entries_on_key_hash', unique: true
    end
  end
end
