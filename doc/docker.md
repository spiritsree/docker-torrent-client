# Docker Options

Docker might need some elevated privileges or other options for this to work without any issues. Below are some of the options which can be used with the docker command.

* **Capability** (`--cap-add=`)

This will add Linux capabilities. There are many capabilities. We mainly use `NET_ADMIN` to do various network related operations. `NET_ADMIN` is required for firewall to started and add rules etc.

e.g: `--cap-add=NET_ADMIN`

* **DNS** (`--dns=[]`)

You can set custom dns options for the container using `--dns=[]` options. You can provide multiple dns options.

e.g: `--dns=8.8.8.8`

* **Sysctl** (`--sysctl`)

You can pass sysctl configs to container. Docker may not support IPv6 in some cases and the container start may fail. You can disable IPv6 with sysctl option.

e.g: `--sysctl net.ipv6.conf.all.disable_ipv6=0`

* **Network** (`--network`)

You can specify a network for the container to connect to. This is useful when you want multiple containers to communicate each other in a single network. The `network=container` will allow you to reuse another container's network stack.

e.g: `--network="container:<name|id>"`

* **Add Host Entry** (`--add-host`)

This will allow you to add a `/etc/host` entry with hostname and IP address.

e.g: `--add-host=srv.example.com:1.1.1.1`

* **Restart Policy** (`--restart`)

This will control containers restart policy. Default is no restart.

e.g: `--restart=always`

* **Logging Drivers** (`--log-driver`)

The container can have a different logging driver than the Docker daemon. This will control how the container logging works.

e.g: `--log-driver=json-file` is the default.

Log size can be controlled with `--log-opt max-size=<size>m`

* **Shared Filesystem** (`--volume=`)

You can use this options to mount a local directory into the container. The directory should be in the shared filesystem option in docker engine config for the mount to work.

e.g: `-v /data:/data`


## Reference

* [Docker Run](https://docs.docker.com/engine/reference/commandline/run/)
* [Docker Run Options](https://docs.docker.com/engine/reference/run/)
* [Linux Capabilities](http://man7.org/linux/man-pages/man7/capabilities.7.html)
* [Configure Logging Driver](https://docs.docker.com/config/containers/logging/configure/)
