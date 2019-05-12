[![build status][251]][232] [![commit][255]][231] [![version:x86_64][256]][235] [![size:x86_64][257]][235] [![version:armhf][258]][236] [![size:armhf][259]][236]

## [Alpine-RSysLog][234]
#### Container for Alpine Linux + RSysLog
---

This [image][233] containerizes the [RSysLog][135] to
forward/collect log files to and from (respectively) between
devices in the network.

This container can collect or aggregate logs from

* the container itself,
* systemd of the host machine running docker via Journald socket,
* from other containers running in the same host via TCP/UDP (default port 514),
* (optionally) receive from (or send them to) remote machines
    using the Reliable Protocol (default port 2514).

Checkout the [rsyslog docs][137] to learn more. Also includes
[logrotate][138] to trim the collected logs daily with a Cron Job.

Based on [Alpine Linux][131] from my [alpine-glibc][132] image with
the [s6][133] init system [overlayed][134] in it.

The image is tagged respectively for the following architectures,
* **armhf**
* **x86_64** (retagged as the `latest` )

**armhf** builds have embedded binfmt_misc support and contain the
[qemu-user-static][105] binary that allows for running it also inside
an x64 environment that has it.

---
#### Get the Image
---

Pull the image for your architecture it's already available from
Docker Hub.

```
# make pull
docker pull woahbase/alpine-rsyslog:x86_64
```

---
#### Run
---

If you want to run images for other architectures, you will need
to have binfmt support configured for your machine. [**multiarch**][104],
has made it easy for us containing that into a docker container.

```
# make regbinfmt
docker run --rm --privileged multiarch/qemu-user-static:register --reset
```

Without the above, you can still run the image that is made for your
architecture, e.g for an x86_64 machine..

This images already has a user `alpine` configured to drop
privileges to the passed `PUID`/`PGID` which is ideal if its used
to run in non-root mode. That way you only need to specify the
values at runtime and pass the `-u alpine` if need be. (run `id`
in your terminal to see your own `PUID`/`PGID` values.)

The configuration for Rsyslog defaults to `/etc/rsyslog.conf`, in
which case you drop your custom configurations at
`/etc/rsyslog.d/`, but to use a different configuration, use the
`RSYSLOG_CONF` variable, an example provided inside
`data/config/rsyslog.conf`. Also, this image includes `logrotate`
for managing the log files by periodically rotating them. A sample
configuration is provied at `data/config/logrotate.conf` which
uses `data/config/logrotate.state` for its state, and a cron job
is set at `/etc/periodic/daily/logrotate`.

To forward logs from Journald to the syslog inside the container,
first make sure `syslog.socket` service is not enabled or running,
(that usually manages the socket at `/run/systemd/journal/syslog.socket`),
then add the following to `/etc/systemd/journald.conf` under the
`Journal` block,

```
[Journal]
ForwardToSyslog=yes
```
and restart the service `systemd-journald`. Might want to set
a name to the docker host instead of 'localhost', in that case set
the name in the environment variable `SYS_HOSTNAME`, and uncomment
the hostname configuration inside the `imuxsock` module input.

To forward logs to a remote host, uncomment the transport type
(TCP/UDP or RELP) in the configuration file at
`data/config/rsyslog.conf`, the host and port to forward to can be
set by the environment variable `FWD_TO_HOST` and `FWD_TO_PORT`,
for TCP/UDP selection use the environment variable `FWD_PROTOCOL`.

Running `make` starts the service.

```
# make
docker run --rm -it \
  --name docker_rsyslog  --hostname rsyslog \
  -c 256 -m 256m \
  -e FWD_PROTOCOL=relp  \
  -e FWD_TO_HOST=logger.local \
  -e FWD_TO_PORT=2514 \
  -e LOGROTATE_CONF=/config/logrotate.conf \
  -e LOGROTATE_STATE=/config/logrotate.state \
  -e PGID=1000 -e PUID=1000 \
  -e RSYSLOG_CONF=/config/rsyslog.conf \
  -e SYS_HOSTNAME=outerhost \
  -e TZ=Asia/Kolkata \
  -p 2514:2514 \
  -p 514:514/tcp \
  -p 514:514/udp \
  -v /etc/hosts:/etc/hosts:ro \
  -v /etc/localtime:/etc/localtime:ro \
  -v /run/systemd/journal:/run/systemd/journal  \
  -v data/config:/config \
  -v data/log:/var/log \
  -v data/spool:/var/spool/rsyslog \
  woahbase/alpine-rsyslog:x86_64
```

Running `make shell` gets a shell.

```
# make shell
docker run --rm -it \
  --entrypoint /bin/bash \
  --name docker_rsyslog  --hostname rsyslog \
  -c 256 -m 256m \
  -e FWD_PROTOCOL=relp  \
  -e FWD_TO_HOST=logger.local \
  -e FWD_TO_PORT=2514 \
  -e LOGROTATE_CONF=/config/logrotate.conf \
  -e LOGROTATE_STATE=/config/logrotate.state \
  -e PGID=1000 -e PUID=1000 \
  -e RSYSLOG_CONF=/config/rsyslog.conf \
  -e SYS_HOSTNAME=outerhost \
  -e TZ=Asia/Kolkata \
  -p 2514:2514 \
  -p 514:514/tcp \
  -p 514:514/udp \
  -v /etc/hosts:/etc/hosts:ro \
  -v /etc/localtime:/etc/localtime:ro \
  -v /run/systemd/journal:/run/systemd/journal  \
  -v data/config:/config \
  -v data/log:/var/log \
  -v data/spool:/var/spool/rsyslog \
  woahbase/alpine-rsyslog:x86_64
```

Stop the container with a timeout, (defaults to 2 seconds)

```
# make stop
docker stop -t 2 docker_rsyslog
```

Removes the container, (always better to stop it first and `-f`
only when needed most)

```
# make rm
docker rm -f docker_rsyslog
```

Restart the container with

```
# make restart
docker restart docker_rsyslog
```

---
#### Shell access
---

Get a shell inside a already running container,

```
# make debug
docker exec -it docker_rsyslog /bin/bash
```

set user or login as root,

```
# make rdebug
docker exec -u root -it docker_rsyslog /bin/bash
```

To check logs of a running container in real time

```
# make logs
docker logs -f docker_rsyslog
```

---
### Development
---

If you have the repository access, you can clone and
build the image yourself for your own system, and can push after.

---
#### Setup
---

Before you clone the [repo][231], you must have [Git][101], [GNU make][102],
and [Docker][103] setup on the machine.

```
git clone https://github.com/woahbase/alpine-rsyslog
cd alpine-rsyslog
```
You can always skip installing **make** but you will have to
type the whole docker commands then instead of using the sweet
make targets.

---
#### Build
---

You need to have binfmt_misc configured in your system to be able
to build images for other architectures.

Otherwise to locally build the image for your system.
[`ARCH` defaults to `x86_64`, need to be explicit when building
for other architectures.]

```
# make ARCH=x86_64 build
# sets up binfmt if not x86_64
docker build --rm --compress --force-rm \
  --no-cache=true --pull \
  -f ./Dockerfile_x86_64 \
  --build-arg ARCH=x86_64 \
  --build-arg DOCKERSRC=alpine-glibc \
  --build-arg PGID=1000 \
  --build-arg PUID=1000 \
  --build-arg USERNAME=woahbase \
  -t woahbase/alpine-rsyslog:x86_64 \
  .
```

To check if its working..

```
# make ARCH=x86_64 test
docker run --rm -it \
  --name docker_rsyslog --hostname rsyslog \
  --entrypoint /bin/bash \
  -e PGID=1000 -e PUID=1000 \
  woahbase/alpine-rsyslog:x86_64 \
  -ec 'sleep 5; rsyslogd -v; logrotate --version;'
```

And finally, if you have push access,

```
# make ARCH=x86_64 push
docker push woahbase/alpine-rsyslog:x86_64
```

---
### Maintenance
---

Sources at [Github][106]. Built at [Travis-CI.org][107] (armhf / x64 builds). Images at [Docker hub][108]. Metadata at [Microbadger][109].

Maintained by [WOAHBase][204].

[101]: https://git-scm.com
[102]: https://www.gnu.org/software/make/
[103]: https://www.docker.com
[104]: https://hub.docker.com/r/multiarch/qemu-user-static/
[105]: https://github.com/multiarch/qemu-user-static/releases/
[106]: https://github.com/
[107]: https://travis-ci.org/
[108]: https://hub.docker.com/
[109]: https://microbadger.com/

[131]: https://alpinelinux.org/
[132]: https://hub.docker.com/r/woahbase/alpine-glibc
[133]: https://skarnet.org/software/s6/
[134]: https://github.com/just-containers/s6-overlay
[135]: https://www.rsyslog.com/
[137]: https://www.rsyslog.com/doc/
[138]: https://linux.die.net/man/8/logrotate

[201]: https://github.com/woahbase
[202]: https://travis-ci.org/woahbase/
[203]: https://hub.docker.com/u/woahbase
[204]: https://woahbase.online/

[231]: https://github.com/woahbase/alpine-rsyslog
[232]: https://travis-ci.org/woahbase/alpine-rsyslog
[233]: https://hub.docker.com/r/woahbase/alpine-rsyslog
[234]: https://woahbase.online/#/images/alpine-rsyslog
[235]: https://microbadger.com/images/woahbase/alpine-rsyslog:x86_64
[236]: https://microbadger.com/images/woahbase/alpine-rsyslog:armhf

[251]: https://travis-ci.org/woahbase/alpine-rsyslog.svg?branch=master

[255]: https://images.microbadger.com/badges/commit/woahbase/alpine-rsyslog.svg

[256]: https://images.microbadger.com/badges/version/woahbase/alpine-rsyslog:x86_64.svg
[257]: https://images.microbadger.com/badges/image/woahbase/alpine-rsyslog:x86_64.svg

[258]: https://images.microbadger.com/badges/version/woahbase/alpine-rsyslog:armhf.svg
[259]: https://images.microbadger.com/badges/image/woahbase/alpine-rsyslog:armhf.svg
