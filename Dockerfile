FROM ruby:3.2.2-alpine3.18

COPY --chmod=750 entrypoint.sh /
COPY Gemfile Gemfile.lock /

RUN apk add --no-cache git bash \
	&& bundle install

ENTRYPOINT ["/entrypoint.sh"]
