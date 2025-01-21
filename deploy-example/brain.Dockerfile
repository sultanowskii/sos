FROM elixir:1.17.3

WORKDIR /app

COPY . .

RUN mix local.hex --force
RUN mix deps.get

CMD ["./deploy-example/brain.sh"]
