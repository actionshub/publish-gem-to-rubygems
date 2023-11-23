FROM ruby:3.2.2-alpine3.18

COPY --link --chmod=750 entrypoint.sh /
COPY --link Gemfile Gemfile.lock /

RUN apk add --no-cache git bash \
	&& bundle install

ENTRYPOINT ["/entrypoint.sh"]
