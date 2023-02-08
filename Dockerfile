FROM ruby:3.2-alpine

LABEL "com.github.actions.name"="Publish Gem to Rubygems" \
  "com.github.actions.icon"="edit-3" \
  "com.github.actions.color"="red" \
  "com.github.actions.description"="Build and publish your gem to Rubygems"

RUN apk add --no-cache git
RUN gem install bundler keycutter
COPY entrypoint.sh /
ENTRYPOINT [ "/entrypoint.sh" ]
