# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Admins', type: :request do
  describe '管理者のリクエスト' do
    context 'ログインしている場合' do
      let!(:admin) { FactoryBot.create(:admin) }

      before do
        sign_in admin, scope: :admin
      end

      it 'indexテンプレートを表示する' do
        get admin_root_url
        expect(response).to be_successful
      end

      it '@blogsにすべてのブログを割り当てること' do
        get admin_root_url
        expect(controller.instance_variable_get(:@blogs)).to eq(Blog.all)
      end

      it 'newアクションで@blogを割り当てること' do
        get admin_root_url
        expect(controller.instance_variable_get(:@blog)).to be_a_new(Blog)
      end
    end

    context 'ログイン情報が未入力の場合' do
      it 'ログインページに回帰する' do
        get new_admin_session_url
        expect(response).to be_successful
      end
    end
  end
end
