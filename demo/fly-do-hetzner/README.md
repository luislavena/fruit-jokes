Simple demo that shows Litestream replication across two different S3-compatible
providers like DigitalOcean and Hetzner

## Create your buckets

For this demo, create one bucket on Digital Ocean (Spaces) inside Amsterdam
region (`ams3`) and another in Nuremberg (`nbg1`).

Then create the read-write S3 keys (Access Key + Secret Key) for each.

Use random names for your buckets.

You can check [Litestream guides](https://litestream.io/guides/#replica-guides)
for instructions on how to setup them.

## Create `secrets.env`

Copy the template file:

```console
$ cp secrets.env.template secrets.env
```

Edit `secrets.env` and replace Replica 1 credentials and bucket information with
the ones from the previous step from Digital Ocean. Repeat this for Replica 2
with the ones from Hetzner.

## Launch the application

```console
$ flyctl launch --generate-name --copy-config --no-deploy
```

The above will create the application, give it a random name, reuse the existing
`fly.toml` configuration, but it will not automatically deploy it.

Export the random name as `APPNAME` for later:

```console
export APPNAME=...
```

## Load the secrets

```console
$ cat secrets.env | flyctl secrets import
```

## Deploy the application

```console
$ flyctl deploy
```

## Validate the application is working

```console
$ curl -s https://$APPNAME.fly.dev | jq .
```

And confirm you got an empty response:

```json
{
  "jokes": []
}
```

## Add your jokes

```console
$ curl -s -X POST https://$APPNAME.fly.dev \
  --data-raw '{"content":"Why did the orange go to the doctor? Because it was not peeling well!"}' | jq .
```

```console
$ curl -s -X POST https://$APPNAME.fly.dev \
  --data-raw '{"content":"What kind of key opens a banana? A monkey!"}' | jq .
```

## Destroy the application

First destroy the machine (VM) running the application:

```console
$ flyctl machine list --json | jq -r ".[]|.id" | xargs fly machine destroy -f
```

Now remove the volume:

```console
$ flyctl volume list --json | jq -r ".[]|.id" | xargs fly volume destroy -y
```

## Remove one of the replicas

At this point, you can delete the contents of one of the replicas, or update
the configuration to point to a new, empty bucket.

## Re-deploy the application

```console
$ flyctl deploy
```

## Validate data has been restored

```console
$ curl -s https://$APPNAME.fly.dev | jq .
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
