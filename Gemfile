# frozen_string_literal: true

source 'https://rubygems.org'
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby '3.2.1'

# Rails 8
gem 'rails', '~> 8.0'

# Asset pipeline
gem 'sprockets-rails', '~> 3.4' # Rails 8 対応版で最新

# DB
gem 'pg', '~> 1.5'

# Webサーバー
gem 'puma', '~> 6.6' # Rails 8 で推奨される 6 系最新

# JavaScript & Hotwire
gem 'importmap-rails', '~> 1.2'
gem 'stimulus-rails', '~> 1.2'
gem 'turbo-rails', '~> 1.4'

# JSON builder
gem 'jbuilder', '~> 2.14' # 最新安定版

# 認証系
gem 'devise', '~> 4.9' # 最新安定版 4.9.4
gem 'devise-i18n', '~> 1.11'

# Windows 専用
gem 'tzinfo-data', platforms: %i[mingw mswin x64_mingw jruby]

# Boot & logger
gem 'bootsnap', '~> 1.16', require: false
gem 'logger', '~> 1.7'

group :development, :test do
  gem 'debug', platforms: %i[mri mingw x64_mingw]
  gem 'rspec-rails', '~> 6.0'
  gem 'rubocop', require: false
  gem 'rubocop-capybara', require: false
  gem 'rubocop-factory_bot', require: false
  gem 'rubocop-rails', require: false
  gem 'rubocop-rspec', require: false
  gem 'rubocop-rspec_rails', require: false
end

group :development do
  gem 'web-console', '~> 4.2'
  # gem "rack-mini-profiler", '~> 3.2'
  # gem "spring", '~> 3.2'
end

group :test do
  gem 'capybara', '~> 3.39'
  gem 'factory_bot_rails', '~> 6.2'
  gem 'selenium-webdriver', '~> 4.10'
  gem 'webdrivers', '~> 5.3'
end
