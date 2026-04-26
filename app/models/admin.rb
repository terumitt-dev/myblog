# frozen_string_literal: true

class Admin < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable, :jwt_authenticatable,
         jwt_revocation_strategy: JwtBlacklist

  validate :only_one_admin_allowed, on: :create

  # Devise の通知メール（パスワードリセット等）を ActiveJob 経由で非同期送信する。
  # デフォルトは deliver_now で SMTP 完了まで同期で待つため、
  # /api/auth/password の応答時間が SECRET の正誤に依存する形で変動し、
  # 202 統一レスポンスでもタイミング差から内部状態を推測される余地が残る。
  # deliver_later にすることでコントローラのレイテンシを平準化する。
  def send_devise_notification(notification, *args)
    devise_mailer.send(notification, self, *args).deliver_later
  end

  private

  def only_one_admin_allowed
    return if Admin.count.zero?

    errors.add(:base, 'Only one admin allowed')
  end
end
