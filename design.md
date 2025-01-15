# Design

(Minimally) AWS S3 API compatible object storage.

## Supported Methods

- `CreateBucket`
- `ListBuckets`
- `DeleteBucket`
- `PutObject`
- `CopyObject`
- `ListObjectsV2`
- `GetObject`
- `DeleteObject`

## Architecture

```mermaid
architecture-beta
    group sos(cloud)[SOS]
    group worker1(cloud)[Worker 1]
    group worker2(cloud)[Worker 2]
    group worker3(cloud)[Worker 3]
    group worker4(cloud)[Worker 4]

    junction junctionWorkersCenter
    junction junctionWorkersRight

    service http_api(internet)[HTTP API] in sos
    service coordinator(server)[Coordinator] in sos
    service db(database)[DB] in sos

    http_api:R -- L:coordinator
    http_api:T -- L:db
    coordinator:T -- B:db

    service storage1(disk)[Storage 1] in worker1
    service storage2(disk)[Storage 2] in worker2
    service storage3(disk)[Storage 3] in worker3
    service storage4(disk)[Storage 4] in worker4

    storage1{group}:B -- T:junctionWorkersCenter
    coordinator{group}:R -- L:junctionWorkersCenter
    storage3{group}:T -- B:junctionWorkersCenter

    junctionWorkersCenter:R -- L:junctionWorkersRight
    storage2{group}:B -- T:junctionWorkersRight
    storage4{group}:T -- B:junctionWorkersRight
```

- `HTTP API` - Partially S3-compatible API 'frontend'
- `Coordinator` - Keeps track of workers and entities. Is responsible for all operations.
- `DB` - Database where all information regarding buckets, objects, etc is stored.
- `Storage` - A worker which _actually_ stores the objects. Doesn't make decisions on its own, it waits for commands from the Coordinator.

## TBD

1. I guess we should be replicating object over all workers
2. Therefore, a distributed transaction is required here
3. And there also should be a way to somehow add another worker / restore the failed one - which would require somehow copying all the objects from one of the healthy workers (so that they are all in the same state)
4. Or maybe we should just have ONE storage worker for the sake of simplicity?
