ARG DEBIAN_VERSION=buster-slim

FROM elixir:1.13 as builder

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

RUN mix escript.build --overwrite

FROM debian:${DEBIAN_VERSION}

ENV RELEASE_NODE="ledboard-tester@127.0.0.1"

WORKDIR /opt/app

RUN apt-get update -qq && apt-get install -y \
  openssl && \
  rm -rf /var/lib/apt/lists/*

COPY --from=builder /opt/app/ledboard_tester ./

ENTRYPOINT ["/opt/app/ledboard_tester"]
CMD ["--ip=1", "--port=2"]