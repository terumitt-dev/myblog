# frozen_string_literal: true

require 'rails_helper'

RSpec.configure do |config|
  config.include Devise::Test::IntegrationHelpers, type: :routing
end
