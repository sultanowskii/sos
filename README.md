# Simple Object Storage (SOS)

Partially S3-compatible, naively distributed object storage.

Written fully in Elixir.

## Overview

The idea is rather simple: There is a "`brain`" - a main component, that exposes S3-compatible HTTP API, stores the meta-info and also communicates with `storage agents`.

There is also a "storage agent" - a component that actually stores objects and communicates with `Brain`. Several instances of them could run on the same machine, as well as on different nodes - as long as each of them has a network access to the `Brain`.

You can think of `SOS` as something similar to [RAID 0](https://en.wikipedia.org/wiki/Standard_RAID_levels#RAID_0): separate "storage"s, each "object" is assigned to a specific "storage". That said, it's considered just a signular "big storage" from user's perspective. In other words, end users of SOS API use it the same way they would use S3 - without even knowking about "storages", "agents", etc.

Brain encapsulates a concept of storage agents, and storage agents encapsulate the way objects are actually stored - which makes both development AND usage quite easy.

### Limitations

- Only several basic methods are supported, see below
- No auth at all
- Several parameters are not implemented

### Supported Methods

- `CreateBucket`
- `ListBuckets`
- `DeleteBucket`
- `PutObject`
- `ListObjectsV2`
- `GetObject`
- `DeleteObject`

### Elixir

In terms of elixir/erlang stack, `Brain` and `Agent`(s) are separate `Node`s - together they form a cluster, where `Brain` makes `GenServer` calls to `Agent`s.

## Install

### Requirements

You'll need:

- [`elixir`](https://elixir-lang.org/)

### Commands

```bash
git clone https://github.com/sultanowskii/sos.git
cd sos
```

## Usage

### Basic local setup

The following setup is only suitable for local environment / experiments. Docker setup is way less tedious, I recommend using it.

#### `Brain`

This is a main component - head/leader/whatever-you-name-it.

```bash
elixir \
    --name server@127.0.0.1 \
    --cookie cookie-example \
    -S mix run -- brain
```

#### `Agent`

This is an actual 'storage' worker.

```bash
elixir \
    --name client@127.0.0.1 \
    --cookie cookie-example \
    -S mix run -- storage-agent --brain-name server@127.0.0.1 --client-id sherlock-holmes --directory sos-data
```

### Docker

A recommended way to setup a SOS cluster.

I recommend to take a look at an example of multi-agent `docker-compose` setup in [deploy-example/](deploy-example/) - it can give you a basic idea of how to start and is actually a working example.

## About

This project is a functional programming course assignment (at ITMO University). The theme is free, I choose to build an object storage. 

elixir is kinda cool.

