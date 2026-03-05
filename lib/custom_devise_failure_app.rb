# frozen_string_literal: true

class CustomDeviseFailureApp < Devise::FailureApp
  def respond
    json_error_response
  end

  private

  def json_error_response
    code = (warden_options[:status] || 401).to_i
    self.status = code
    self.content_type = 'application/json'
    self.headers['WWW-Authenticate'] = 'Bearer' if code == 401
    self.response_body = [
      {
        status: 'error',
        message: i18n_message
      }.to_json
    ]
  end
end
