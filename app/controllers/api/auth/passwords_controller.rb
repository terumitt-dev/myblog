# frozen_string_literal: true

module Api
  module Auth
    # パスワードリセット用コントローラー
    # Admin は singleton（1人のみ）の設計のため、
    # - Email 入力を省略し、ボタン1つでリセット要求できる
    # - ただし誰でもメール送信をトリガーできると爆撃されるため、
    #   PASSWORD_RESET_SECRET 環境変数で保護する
    class PasswordsController < ApplicationController
      # PASSWORD_RESET_SECRET をクラス読み込み時に必須化することで、
      # デプロイ時の設定漏れを起動時に fail-fast で検知する
      # （未設定のままだと create が常に 202 を返して silent fail し、
      #  運用上気付けないため）。
      # ENV.fetch は未設定だけ弾くので、空文字 ("PASSWORD_RESET_SECRET=") も
      # 別途 blank? で拒否する。
      # SHA-256 ダイジェストも事前計算してメモ化（リクエスト毎の計算を避ける）。
      PASSWORD_RESET_SECRET = ENV.fetch('PASSWORD_RESET_SECRET').tap do |value|
        raise 'PASSWORD_RESET_SECRET must not be blank' if value.blank?
      end.freeze
      EXPECTED_SECRET_DIGEST = OpenSSL::Digest::SHA256.hexdigest(PASSWORD_RESET_SECRET).freeze

      # SECRET を検証して OK ならリセットメールを送信
      # POST /api/auth/password
      # Body: { "secret": "..." }
      #
      # セキュリティ方針: SECRET の正誤・Admin 不存在・SMTP 失敗のいずれも
      # 同じレスポンス（202 Accepted）を返す。これにより攻撃者が応答の差分から
      # SECRET やシステム状態を推測する「オラクル攻撃」を防ぐ。
      # 内部エラーはログのみに残す。
      def create
        # 全処理を rescue で包んで「常に 202 を返す」を保証する。
        # DB 障害・ジョブ投入失敗・予期せぬ例外のいずれも 500 にならず、
        # 攻撃者が応答コードの差分から内部状態を推測できないようにする。
        #
        # secret の取り出し (request.request_parameters) も rescue 内に入れる。
        # 不正な JSON ボディが POST されると parse error が投げられるため、
        # rescue の外に出していると「不正 JSON で 500、正常 JSON で 202」の差分が
        # 観測されてオラクルになる。
        begin
          # クエリ文字列経由で secret を渡されると URL / アクセスログ / Referer 経由で
          # 漏えいする経路が残る。リクエストボディ (JSON / form) からのみ受け付ける。
          secret = request.request_parameters['secret']

          # secret の正誤に関わらず Admin の取得まで常に実行することで、
          # DB アクセスの有無による応答時間差を排除する。
          # メール送信自体は valid な場合のみだが、deliver_later 化済みのためそのコストは
          # ほぼゼロに揃う。
          admins = Admin.limit(2).to_a

          if valid_secret?(secret)
            # singleton 前提が崩れている場合はログのみで握り潰し、レスポンスは統一
            if admins.one?
              admins.first.send_reset_password_instructions
            else
              Rails.logger.error("Unexpected admin count for password reset: #{admins.size}")
            end
          end
        rescue StandardError => e
          # DB 障害・ジョブ投入失敗・SMTP 障害・JSON parse 失敗等すべて握り潰してログのみ。
          # e.message は JSON parse 失敗時にリクエストボディの断片を含み得るため
          # (例: "unexpected token at '{\"secret\":\"...\"'") secret 漏えいの危険がある。
          # filter_parameters は自前ログ行には効かないので、メッセージは出さず
          # 例外クラスと request_id だけで原因追跡できるようにする。
          Rails.logger.error(
            "Password reset request handling failed: #{e.class} request_id=#{request.request_id}"
          )
        end

        render json: { message: 'If the request was accepted, a password reset email will be sent' },
               status: :accepted
      end

      # リセットトークンで新しいパスワードを設定
      # PATCH /api/auth/password
      # Body: { "reset_password_token": "...", "password": "...", "password_confirmation": "..." }
      #
      # ステータスコードでエラー種別を区別する（フロントエンドの分岐を簡潔にするため）:
      # - 200 OK                       … 更新成功
      # - 401 Unauthorized             … トークン不正・期限切れ・欠落（再リセット要求が必要）
      # - 422 Unprocessable Entity     … パスワードバリデーション失敗（同じトークンで再入力可能）
      def update
        admin = Admin.reset_password_by_token(reset_params)

        if admin.errors.empty?
          render json: { message: 'Password updated successfully' }, status: :ok
        elsif admin.errors[:reset_password_token].present?
          # Devise が token 不正/欠落/期限切れを reset_password_token 属性のエラーとして返す。
          # これらはトークン自体が使えない状態なので、フロントエンド側で sessionStorage を
          # クリアして「再リセット要求」画面に誘導すべきケース。
          render json: { errors: admin.errors.full_messages }, status: :unauthorized
        else
          # password 属性のバリデーションエラー（短い・確認不一致など）。
          # トークンは有効なので、フロントエンド側ではエラー表示後に同じトークンで再送可能。
          render json: { errors: admin.errors.full_messages }, status: :unprocessable_entity
        end
      rescue StandardError => e
        # DB 障害等の想定外例外で Rails の既定 500 (HTML or 空) に落ちると、
        # フロントエンドが JSON parse 失敗してエラー画面が表示できなくなる。
        # 必ず JSON で返すことで、API クライアント側の表示・分岐ロジックを維持する。
        # e.message には reset_password_token の値が含まれる可能性があるため
        # (例: SQL インジェクション攻撃ペイロードがそのまま例外メッセージに混入する等)、
        # ログには例外クラスと request_id のみ記録する (create と同じ防御パターン)。
        Rails.logger.error(
          "Password reset update failed: #{e.class} request_id=#{request.request_id}"
        )
        render json: { errors: ['Password reset could not be completed'] },
               status: :internal_server_error
      end

      private

      def valid_secret?(input)
        return false if input.blank?

        # 入力を SHA-256 でハッシュ化してから比較することで、常に固定長 (64文字) 同士の
        # 比較となる。secure_compare は長さ不一致時に早期 return するため、理論上
        # 「入力長 != 期待長」がタイミングから漏れる余地がある。
        # ハッシュ化により秘密長そのものを露出しないことを担保する。
        # 期待値側のダイジェストはクラス定数で事前計算済み。
        input_digest = OpenSSL::Digest::SHA256.hexdigest(input.to_s)
        ActiveSupport::SecurityUtils.secure_compare(input_digest, EXPECTED_SECRET_DIGEST)
      end

      def reset_params
        # secret 同様、reset_password_token もクエリ文字列経由で渡されると
        # URL / アクセスログ / Referer 経由で漏えいする経路が残るため、
        # リクエストボディ (JSON / form) からのみ受け付ける。
        # 不正な JSON ボディが POST されると request.request_parameters が
        # parse error を投げるため、空ハッシュにフォールバックして update が
        # 必ず JSON で 401/422 を返せるようにする (フレームワーク既定の 400/500 にしない)。
        body =
          begin
            request.request_parameters
          rescue StandardError
            {}
          end
        ActionController::Parameters.new(
          body.slice('reset_password_token', 'password', 'password_confirmation')
        ).permit(:reset_password_token, :password, :password_confirmation)
      end
    end
  end
end
