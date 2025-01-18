FROM elixir:1.17.3

WORKDIR /app

COPY . .

ENTRYPOINT ["bash"]
