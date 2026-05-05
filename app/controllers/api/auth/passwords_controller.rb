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
          # トップレベル `::Admin` 明示は必須。`Admin` 単体だと
          # `Api::Auth::PasswordsController` から見て `Api::Admin` (controllers/api/admin/
          # 配下が作るモジュール定数) に先に解決され、`undefined method 'limit' for
          # Api::Admin:Module` の NoMethodError になる。
          admins = ::Admin.limit(2).to_a

          # 応答時間差を完全に揃えるため、valid/invalid いずれの secret でも同じ work
          # (= PasswordResetRequestJob を 1 件 enqueue) を実行する。
          # トークン発行 + メール送信を行うかどうかは send_reset フラグでジョブ側が判断。
          # 以前は valid 時のみ send_reset_password_instructions を controller 同期実行
          # していたため、DB UPDATE (set_reset_password_token) のぶん応答時間差が残っていた。
          secret_valid = valid_secret?(secret)
          if secret_valid && !admins.one?
            # singleton 前提が崩れた状態でも attacker から見える挙動は変えない (ログのみ)
            Rails.logger.error("Unexpected admin count for password reset: #{admins.size}")
          end

          PasswordResetRequestJob.perform_later(
            admin_id: admins.one? ? admins.first.id : nil,
            send_reset: secret_valid && admins.one?
          )
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
        # singleton 前提が崩れた状態 (Admin が 0 件 or 2 件以上) では更新を拒否する。
        # reset_password_by_token はトークンに紐づく 1 件しか更新しないため漏洩リスクは
        # 元々ないが、create 側の admins.one? ガードと挙動を一貫させ、異常系では token
        # を消費させない (= 認証不可エラーに統一する) ことで運用での原因切り分けを容易にする。
        # `::Admin` 明示の理由は create と同じ (`Api::Admin` namespace 衝突回避)。
        # `.limit(2).to_a.size` を使うのは `.limit(2).count` だと SQL 上 LIMIT が
        # COUNT(*) に効かず実質 `Admin.count` 相当で全件 SCAN される (admin が増えた
        # 場合の性能劣化) のと、`create` 側 (`limit(2).to_a` を使う) と取得方法を
        # 揃えるため。
        admin_count = ::Admin.limit(2).to_a.size
        unless admin_count == 1
          Rails.logger.error("Unexpected admin count for password reset update: #{admin_count}")
          render json: { errors: ['Password reset could not be completed'] },
                 status: :unauthorized
          return
        end

        admin = ::Admin.reset_password_by_token(reset_params)

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
        # 入力を SHA-256 でハッシュ化してから比較することで、常に固定長 (64文字) 同士の
        # 比較となる。secure_compare は長さ不一致時に早期 return するため、理論上
        # 「入力長 != 期待長」がタイミングから漏れる余地がある。
        # ハッシュ化により秘密長そのものを露出しないことを担保する。
        # 期待値側のダイジェストはクラス定数で事前計算済み。
        #
        # blank? による早期 return は意図的に置かない。早期 return すると blank/non-blank
        # で SHA256 + secure_compare の実行有無が分かれて応答時間差が生じうるため、
        # nil/空文字でも常に同じパス (input.to_s -> SHA256 -> secure_compare) を通す。
        # input.to_s で nil は "" に、空文字はそのまま SHA256 にかかるので副作用なし。
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
