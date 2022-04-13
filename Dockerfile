FROM ruby:3.1-alpine

RUN apk add --no-cache git
RUN gem install bundler keycutter
COPY entrypoint.sh /
ENTRYPOINT [ "/entrypoint.sh" ]
