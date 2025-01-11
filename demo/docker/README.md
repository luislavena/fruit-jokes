Simple demo that showcases the usage of Litestream with two replicas. It uses
MinIO as a local S3-compatible backup.

## Run the demo

```console
$ docker compose up
```

Wait a few seconds as the serivce waits for MinIO to start.

## List existing jokes

```console
$ curl -s localhost:3000 | jq .
```

```json
{
  "jokes": []
}
```

On a fresh start, the list will be empty.

## Add some jokes

```console
$ curl -s -X POST localhost:3000 \
  --data-raw '{"content":"Why did the orange go to the doctor? Because it was not peeling well!"}' | jq .
```

```json
{
  "joke": {
    "id": 1,
    "content": "Why did the orange go to the doctor? Because it was not peeling well!",
    "created_at": "2025-01-11T16:07:14Z"
  }
}
```

```console
$ curl -s -X POST localhost:3000 \
  --data-raw '{"content":"What kind of key opens a banana? A monkey!"}' | jq .
```

## Destroy the application

Now that we have data in, we can test if data is properly restored.

Remove the app and its volume:

```console
$ docker compose rm --stop --force app

$ docker volume rm jokes_app
```

Start the application again:

```console
$ docker compose up -d app
```

And see in the logs that it restored from one of the replicas:

```log
level=INFO msg="restoring snapshot" db=/var/lib/fruit-jokes/fruit-jokes.db replica=replica_1 ...
...
level=INFO msg="renaming database from temporary location" db=/var/lib/fruit-jokes/fruit-jokes.db replica=replica_1
INFO: Starting application using Litestream...
```

## Destroy application and one replica

Now we need to validate if the application can work in case of one of the
replicas fails.

Remove the application and replica1:

```console
$ docker compose rm --stop --force app

$ docker volume rm jokes_app

$ docker compose rm --stop --force replica1

$ docker volume rm jokes_replica1
```

And boot the application again:

```console
$ docker compose up -d
```

Confirm in the logs that Litestream restored from replica_2 instead:

```log
level=INFO msg="restoring snapshot" db=/var/lib/fruit-jokes/fruit-jokes.db replica=replica_2
...
level=INFO msg="renaming database from temporary location" db=/var/lib/fruit-jokes/fruit-jokes.db replica=replica_2
```

And validate that all data is there:

```console
$ curl -s localhost:3000 | jq .
```

```json
{
  "jokes": [
    {
      "id": 2,
      "content": "What kind of key opens a banana? A monkey!",
      "created_at": "2025-01-11T16:09:44Z"
    },
    {
      "id": 1,
      "content": "Why did the orange go to the doctor? Because it was not peeling well!",
      "created_at": "2025-01-11T16:07:14Z"
    }
  ]
}
```
