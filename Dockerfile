ARG DEBIAN_VERSION=buster-slim

FROM elixir:1.11.4 as builder

USER root
ENV MIX_ENV=prod

RUN apt-get update -y && \
  apt-get install git make -y

RUN yes | mix local.hex --force && \
  yes | mix local.rebar --force

WORKDIR /opt/app

COPY mix.exs mix.lock ./

RUN mix do deps.get, deps.compile

COPY . .

RUN mix release

FROM debian:${DEBIAN_VERSION}

ENV RELEASE_NODE="ledboard-tester@127.0.0.1"

WORKDIR /opt/app

RUN apt-get update -qq && apt-get install -y \
  openssl && \
  rm -rf /var/lib/apt/lists/*

COPY --from=builder /opt/app/_build/prod/rel/ledboard_tester ./

ENV HOST 127.0.0.1
ENV PORT 12345

CMD bin/ledboard_tester eval "LedboardTester.main()"