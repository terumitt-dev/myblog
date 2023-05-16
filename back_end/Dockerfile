FROM ruby:3.2.1

RUN apt-get update && apt-get install -y nodejs postgresql-client --no-install-recommends && rm -rf /var/lib/apt/lists/*

WORKDIR /back_end

COPY Gemfile Gemfile.lock ./
RUN gem install bundler && bundle config --global frozen 1 && bundle install

ENV PATH="/usr/local/bundle/bin:${PATH}"
