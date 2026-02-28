# frozen_string_literal: true

# 許可するOriginを一元管理
ALLOWED_ORIGINS = if Rails.env.production?
                    [
                      'https://go-lilaregard.com',
                      'https://www.go-lilaregard.com'
                    ]
                  else
                    [
                      'http://localhost:5173',
                      'http://localhost:3000',
                      'http://127.0.0.1:5173',
                      'http://127.0.0.1:3000'
                    ]
                  end.freeze
