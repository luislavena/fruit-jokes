# fruit-jokes

This application has been set up to demo how [Litestream] can be used with
multiple replicas to ensure durability of your data.

This is following the 3-2-1 backup strategy:

* 3 copies of your data
* 2 copies in different storage devices
* 1 copy off-site

One copy of your data runs with your application. The other two copies live on
different storage services, with one service being different from the other.
This helps ensure backup safety.

## Demos

- [`demo/docker`](./demo/docker) -- local playground for testing replicas
- [`demo/fly-do-hetzner`](./demo/fly-do-hetzner) -- deploy the application to
[Fly.io] and replicas to Digital Ocean and Hetzner

## Why Fruit Jokes?

The name comes as an homage to [Kramer's attempt to build his new
application](https://festivus.dev/kubernetes/), following all the new trends of
the industry. Happy [Festivus]!

## License

Licensed under the Apache License, Version 2.0. You may obtain a copy of
the license [here](./LICENSE).

[Litestream]: https://litestream.io
[Fly.io]: https://fly.io
[Festivus]: https://festivus.dev/
