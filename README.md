# functional-programming-lab3

Выполнили:<br>
1. `Султанов Артур Радикович` (`367553`)
2. `Нягин Михаил Алексеевич` (`368601`)

## Задание

Цель: получить навыки работы со специфичными для выбранной технологии/языка программирования приёмами.

### Требования

* программа должна быть реализована в функциональном стиле;
* требуется использовать идиоматичный для технологии стиль программирования;
* задание и коллектив должны быть согласованы;
* допустима совместная работа над одним заданием.

### Содержание отчёта

* титульный лист;
* требования к разработанному ПО, включая описание алгоритма;
* реализация с минимальными комментариями;
* ввод/вывод программы;
* выводы (отзыв об использованных приёмах программирования).

---

## Требование к разрабаотанному ПО

Реализациия S3 хранилища с api, совместимым c aws S3 api

Доступны следующие методы:

- `CreateBucket`
- `ListBuckets`
- `DeleteBucket`
- `PutObject`
- `CopyObject`
- `ListObjectsV2`
- `GetObject`
- `DeleteObject`

Подробнее об архитектуре в [design.md](https://github.com/sultanowskii/sos/blob/main/design.md)


## Реализация с минимальными комментариями;

### Хранилка(Storage)

Включает в себя api с методами для работы с объектами

Подключается и "общается" с координатором при помощи `Node.connect()`. Таким образом хранилки и их количество полностью независимо от основной части приложения. 

Чтобы запустить хранилку через консоль:
```Elixir
elixir \
    --name client@127.0.0.1 \
    --cookie cookie-example \
    -S mix run -- storage-agent --brain-name server@127.0.0.1 --client-id sherlock-holmes
```
Подробнее о деталях запуска и конфигурации в [Contributing.md](https://github.com/sultanowskii/sos/blob/main/CONTRIBUTING.md)

Супервизор, который при инициализации подключается к центру
```Elixir 
defmodule StorageAgent.Cmd do
  @moduledoc """
  Storage Agent entrypoint.
  """
  alias StorageAgent.Argparser
  require Logger

  def start(args) do
    config = Argparser.parse!(args)

    connected =
      config.brain_name
      |> String.to_atom()
      |> Node.connect()

    case connected do
      true ->
        IO.puts("connected to the brain")

        children = [
          {StorageAgent, config}
        ]

        opts = [strategy: :one_for_one, name: StorageAgent.Supervisor]

        Supervisor.start_link(children, opts)

      false ->
        UIO.eputs("can't connect to the brain")
    end
  rescue
    e in OptionParser.ParseError ->
      UIO.eputs(e.message)
      exit({:shutdown, 1})
  end
end
```


### База данных

В качестве базы данных используется `mnesia`
```plain
A distributed key-value DBMS

The following are some of the most important and attractive capabilities provided by Mnesia:

* A relational/object hybrid data model that is suitable for telecommunications applications.
* A DBMS query language, Query List Comprehension (QLC) as an add-on library.
* Persistence. Tables can be coherently kept on disc and in the main memory.
* Replication. Tables can be replicated at several nodes.
Atomic transactions. A series of table manipulation operations can be grouped into a single atomic transaction.
* Location transparency. Programs can be written without knowledge of the actual data location.
*Extremely fast real-time data searches.
* Schema manipulation routines. The DBMS can be reconfigured at runtime without stopping the system.
```

База данных предоставляет свое api, используя `GenServer`. "общение" c базой данных инициализируется при помощи `Supervisor` координатора

### Координатор

Основное приложение, которое предоставляет aws api.

Для запуска координатора необходимо выполнить команду
```bash
elixir \                                                    
    --name server@127.0.0.1 \
    --cookie cookie-example \
    -S mix run -- brain                                    
```
Подробнее о деталях запуска и конфигурации в [Contributing.md](https://github.com/sultanowskii/sos/blob/main/CONTRIBUTING.md)


Включаетв себя `Supervisor`, контролирующий работу процессов

```Elixir
defmodule Brain.Cmd do
  @moduledoc """
  Brain entrypoint.
  """
  require Logger

  def start(_args) do
    children = [
      {
        Bandit,
        scheme: :http, plug: Brain.Router, port: 8080
      },
      {Brain.Coordinator, []},
      {Db.MnesiaProvider, []}
    ]

    opts = [strategy: :one_for_one, name: Brain.Supervisor]

    Registry.start_link(name: BrainRegistry, keys: :unique)

    Logger.info("Starting application...")

    Supervisor.start_link(children, opts)
  end
end
```

а также `api_router` для взаимодействия с внешними подключениями

```Elixir
defmodule Brain.ApiRouter do
  @moduledoc """
  API Endpoints router.
  """
  alias Brain.ApiSerice
  alias Brain.Mapper

  use Plug.Router
  use Plug.ErrorHandler

  require Logger

  plug(:match)
  plug(:dispatch)

  @spec key_from_tokens([binary()]) :: binary()
  def key_from_tokens(tokens) do
    tokens |> Enum.join("/")
  end

  # ListBuckets
  get "/" do
    conn = fetch_query_params(conn)

    resp =
      ApiSerice.list_buckets()
      |> Mapper.map_resp_list_buckets()
      |> XmlBuilder.generate()

    send_resp(conn, 200, resp)
  end

  # ListObjectsV2
  # Supported params:
  # - list-type
  get "/:bucket" do
    conn = fetch_query_params(conn)
    params = conn.query_params
    _list_type = params["list-type"]

    resp =
      ApiSerice.list_objects(bucket)
      |> Mapper.map_resp_list_objects()
      |> XmlBuilder.generate()

    send_resp(conn, 200, resp)
  end

  # CreateBucket
  put "/:bucket" do
    ApiSerice.create_bucket(bucket)
    conn |> put_resp_header("location", "/#{bucket}")
    send_resp(conn, 200, "")
  end

  # DeleteBucket
  delete "/:bucket" do
    ApiSerice.delete_bucket(bucket)
    send_resp(conn, 204, "")
  end

  # PutObject / CopyObject
  # Supported headers:
  # - x-amz-copy-source
  put "/:bucket/*key_parts" do
    key = key_from_tokens(key_parts)
    conn = fetch_query_params(conn)
    copy_source = conn |> get_req_header("x-amz-copy-source")

    case copy_source do
      [] ->
        # PutObject
        case Plug.Conn.read_body(conn) do
          {:ok, request_data, conn} ->
            result = ApiSerice.put_object(bucket, key, request_data)

            case result do
              :ok ->
                send_resp(conn, 200, "")

              e = {:error, _} ->
                handle_error(conn, e)
            end

          e = {:error, _} ->
            handle_error(conn, e)
        end

      _ ->
        # CopyObject
        send_resp(conn, 501, "copy is not supported")
    end
  end

  # GetObject
  get "/:bucket/*key_parts" do
    key = key_from_tokens(key_parts)
    result = ApiSerice.get_object(bucket, key)

    case result do
      {:ok, data} ->
        send_resp(conn, 200, data)

      e = {:error, _} ->
        handle_error(conn, e)
    end
  end

  # DeleteObject
  delete "/:bucket/*key_parts" do
    key = key_from_tokens(key_parts)
    result = ApiSerice.delete_object(bucket, key)

    case result do
      :ok ->
        send_resp(conn, 204, "")

      e = {:error, _} ->
        handle_error(conn, e)
    end
  end

  match _ do
    request_url = request_url(conn)
    Logger.debug("attempted to access #{inspect(request_url)}, #{inspect(conn)}")
    send_resp(conn, 404, "{}")
  end

  defp handle_error(conn, e) do
    case e do
      {:error, :coordinator_unavailable} ->
        Logger.warning("API: coordinator isn't found in registry")
        send_resp(conn, 503, "service unavailable")

      {:error, :agents_unavailable} ->
        Logger.warning("API: no agent is available")
        send_resp(conn, 503, "service unavailable")

      _ ->
        Logger.warning("API: unexpected error #{inspect(e)}")
        send_resp(conn, 500, "unexpected error")
    end
  end
end
```

## Пример работы программы
Подробнее о деталях запуска и конфигурации в [Contributing.md](https://github.com/sultanowskii/sos/blob/main/CONTRIBUTING.md)


TODO
```bash

```

## Выводы
В ходе данной лабораторной работы, использовав различные инструменты elixir реализовали s3 хранилище совместимое с aws. 