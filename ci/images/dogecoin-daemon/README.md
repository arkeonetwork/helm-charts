# dogecoin-core

## What is Dogecoin Core?

Dogecoin Core is a reference client that implements the Dogecoin protocol for remote procedure call (RPC) use. It is also the second Dogecoin client in the network's history. Learn more about Dogecoin Core on the [Dogecoin Developer Reference docs](https://dogecoin.org/en/developer-reference).

## Usage

### How to use this image

This image contains the main binaries from the Dogecoin Core project - `dogecoind`, `dogecoin-cli` and `dogecoin-tx`. It behaves like a binary, so you can pass any arguments to the image and they will be forwarded to the `dogecoind` binary:

```sh
❯ docker run --rm -it dogecoin-core \
  -printtoconsole \
  -regtest=1 \
  -rpcallowip=172.17.0.0/16 \
  -rpcauth='foo:7d9ba5ae63c3d4dc30583ff4fe65a67e$9e3634e81c11659e3de036d0bf88f89cd169c1039e6e09607562d54765c649cc'
```

_Note: [learn more](#using-rpcauth-for-remote-authentication) about how `-rpcauth` works for remote authentication._

By default, `dogecoind` will run as user `dogecoin` for security reasons and with its default data dir (`~/.dogecoin`). If you'd like to customize where `dogecoin-core` stores its data, you must use the `DOGECOIN_DATA` environment variable. The directory will be automatically created with the correct permissions for the `dogecoin` user and `dogecoin-core` automatically configured to use it.

```sh
❯ docker run --env DOGECOIN_DATA=/var/lib/dogecoin-core --rm -it dogecoin-core \
  -printtoconsole \
  -regtest=1
```

You can also mount a directory in a volume under `/home/dogecoin/.dogecoin` in case you want to access it on the host:

```sh
❯ docker run -v ${PWD}/data:/home/dogecoin/.dogecoin -it --rm dogecoin-core \
  -printtoconsole \
  -regtest=1
```

You can optionally create a service using `docker-compose`:

```yml
dogecoin-core:
  image: dogecoin-core
  command: -printtoconsole
    -regtest=1
```

### Using RPC to interact with the daemon

There are two communications methods to interact with a running Dogecoin Core daemon.

The first one is using a cookie-based local authentication. It doesn't require any special authentication information as running a process locally under the same user that was used to launch the Dogecoin Core daemon allows it to read the cookie file previously generated by the daemon for clients. The downside of this method is that it requires local machine access.

The second option is making a remote procedure call using a username and password combination. This has the advantage of not requiring local machine access, but in order to keep your credentials safe you should use the newer `rpcauth` authentication mechanism.

#### Using cookie-based local authentication

Start by launch the Dogecoin Core daemon:

```sh
❯ docker run --rm --name dogecoin-server -it dogecoin-core \
  -printtoconsole \
  -regtest=1
```

Then, inside the running `dogecoin-server` container, locally execute the query to the daemon using `dogecoin-cli`:

```sh
❯ docker exec --user dogecoin dogecoin-server dogecoin-cli -regtest getmininginfo

{
  "blocks": 0,
  "currentblocksize": 0,
  "currentblockweight": 0,
  "currentblocktx": 0,
  "difficulty": 4.656542373906925e-10,
  "errors": "",
  "networkhashps": 0,
  "pooledtx": 0,
  "chain": "regtest"
}
```

In the background, `dogecoin-cli` read the information automatically from `/home/dogecoin/.dogecoin/regtest/.cookie`. In production, the path would not contain the regtest part.

#### Using rpcauth for remote authentication

Before setting up remote authentication, you will need to generate the `rpcauth` line that will hold the credentials for the Dogecoind Core daemon. You can either do this yourself by constructing the line with the format `<user>:<salt>$<hash>` or use the official [`rpcauth.py`](https://github.com/dogecoin/dogecoin/blob/master/share/rpcauth/rpcauth.py) script to generate this line for you, including a random password that is printed to the console.

_Note: This is a Python 3 script. use `[...] | python3 - <username>` when executing on macOS._

Example:

```sh
❯ curl -sSL https://raw.githubusercontent.com/dogecoin/dogecoin/master/share/rpcauth/rpcauth.py | python - <username>

String to be appended to dogecoin.conf:
rpcauth=foo:7d9ba5ae63c3d4dc30583ff4fe65a67e$9e3634e81c11659e3de036d0bf88f89cd169c1039e6e09607562d54765c649cc
Your password:
qDDZdeQ5vw9XXFeVnXT4PZ--tGN2xNjjR4nrtyszZx0=
```

Note that for each run, even if the username remains the same, the output will be always different as a new salt and password are generated.

Now that you have your credentials, you need to start the Dogecoin Core daemon with the `-rpcauth` option. Alternatively, you could append the line to a `dogecoin.conf` file and mount it on the container.

Let's opt for the Docker way:

```sh
❯ docker run --rm --name dogecoin-server -it dogecoin-core \
  -printtoconsole \
  -regtest=1 \
  -rpcallowip=172.17.0.0/16 \
  -rpcauth='foo:7d9ba5ae63c3d4dc30583ff4fe65a67e$9e3634e81c11659e3de036d0bf88f89cd169c1039e6e09607562d54765c649cc'
```

Two important notes:

1. Some shells require escaping the rpcauth line (e.g. zsh), as shown above.
2. It is now perfectly fine to pass the rpcauth line as a command line argument. Unlike `-rpcpassword`, the content is hashed so even if the arguments would be exposed, they would not allow the attacker to get the actual password.

You can now connect via `dogecoin-cli` or any other compatible clients. You will still have to define a username and password when connecting to the Dogecoin Core RPC server.

To avoid any confusion about whether or not a remote call is being made, let's spin up another container to execute `dogecoin-cli` and connect it via the Docker network using the password generated above:

```sh
❯ docker run -it --link dogecoin-server --rm dogecoin-core \
  dogecoin-cli \
  -rpcconnect=dogecoin-server \
  -regtest \
  -rpcuser=foo\
  -stdinrpcpass \
  getbalance
```

Enter the password `qDDZdeQ5vw9XXFeVnXT4PZ--tGN2xNjjR4nrtyszZx0=` and hit enter:

```
0.00000000
```

Note: under Dogecoin Core < 0.16, use `-rpcpassword="qDDZdeQ5vw9XXFeVnXT4PZ--tGN2xNjjR4nrtyszZx0="` instead of `-stdinrpcpass`.

Done!

### Exposing Ports

Depending on the network (mode) the Dogecoin Core daemon is running as well as the chosen runtime flags, several default ports may be available for mapping.

Ports can be exposed by mapping all of the available ones (using `-P` and based on what `EXPOSE` documents) or individually by adding `-p`. This mode allows assigning a dynamic port on the host (`-p <port>`) or assigning a fixed port `-p <hostPort>:<containerPort>`.

Example for running a node in `regtest` mode mapping JSON-RPC/REST (18443) and P2P (18444) ports:

```sh
docker run --rm -it \
  -p 18443:18443 \
  -p 18444:18444 \
  dogecoin-core \
  -printtoconsole \
  -regtest=1 \
  -rpcallowip=172.17.0.0/16 \
  -rpcbind=0.0.0.0 \
  -rpcauth='foo:7d9ba5ae63c3d4dc30583ff4fe65a67e$9e3634e81c11659e3de036d0bf88f89cd169c1039e6e09607562d54765c649cc'
```

To test that mapping worked, you can send a JSON-RPC curl request to the host port:

```
curl --data-binary '{"jsonrpc":"1.0","id":"1","method":"getnetworkinfo","params":[]}' http://foo:qDDZdeQ5vw9XXFeVnXT4PZ--tGN2xNjjR4nrtyszZx0=@127.0.0.1:18443/
```

#### Mainnet

- JSON-RPC/REST: 8332
- P2P: 8333

## Docker

This image is officially supported on Docker version 17.09, with support for older versions provided on a best-effort basis.

## License

[License information](https://github.com/dogecoin/dogecoin/blob/master/COPYING) for the software contained in this image.