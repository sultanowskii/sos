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

    service storage1(disk)[Storage Agent 1] in worker1
    service storage2(disk)[Storage Agent 2] in worker2
    service storage3(disk)[Storage Agent 3] in worker3
    service storage4(disk)[Storage Agent 4] in worker4

    storage1{group}:B -- T:junctionWorkersCenter
    coordinator{group}:R -- L:junctionWorkersCenter
    storage3{group}:T -- B:junctionWorkersCenter

    junctionWorkersCenter:R -- L:junctionWorkersRight
    storage2{group}:B -- T:junctionWorkersRight
    storage4{group}:T -- B:junctionWorkersRight
```


Database diagrams  
```mermaid
erDiagram
    STORAGE {
        string name PK "name"
        boolean availability "availability"
    }

    OBJECT {
        string name PK "name"
        string bucket_name PK "bucket_name"
        string bucket_name FK "bucket identifier"
        string storage_name FK "storage identifier"
        int size "size of stored object"
        time created_at "meta information"
    }

    BUCKET {
        string name PK "name"
        time created_at "meta information"
    }

    OBJECT ||--|| BUCKET : OneToOne
    OBJECT ||--|| STORAGE : OneToOne
```

- `HTTP API` - Partially S3-compatible API 'frontend'
- `Coordinator` - Keeps track of workers and entities. Is responsible for all operations.
- `DB` - Database where all information regarding buckets, objects, etc is stored.
- `Storage` - A worker which _actually_ stores the objects. Doesn't make decisions on its own, it waits for commands from the Coordinator.
