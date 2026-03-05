FROM ruby:4.0-alpine

RUN apk add --no-cache git bash

COPY --link --chmod=750 entrypoint.sh /

ENTRYPOINT ["/entrypoint.sh"]
