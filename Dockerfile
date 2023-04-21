FROM ruby:3.2.1

RUN apt-get update && apt-get install -y nodejs postgresql-client --no-install-recommends && rm -rf /var/lib/apt/lists/*
RUN apt-get update -qq && apt-get install -y build-essential libpq-dev nodejs

WORKDIR /myblog

COPY Gemfile Gemfile.lock ./
RUN bundle install

CMD bin/rails db:create && bin/rails db:migrate && bin/rails server -b 0.0.0.0
