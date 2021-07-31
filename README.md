# Interactivity Three Ways (ICS branch)

This repository contains the source code that Norman Walsh and Michael Sperberg-McQueen
describe in their Balisage 2021 paper, “[Interactivity Three Ways](https://ndw.github.io/i3w/paper/)”.
The paper [was presented](https://ndw.github.io/i3w/presentation/) on 1 August 2021 at
_[Balisage: The Markup Conference](https://www.balisage.net/)_.

The [generated website](https://ndw.github.io/i3w/) provides
interactive demonstrations of all three approaches.

## ICS branch

This branch differs from the main branch in that the `schedule.xsl` stylesheet in the
“Using Saxon-JS” approach also generates an [iCalendar](https://en.wikipedia.org/wiki/ICalendar)
version of the schedule that you can download.

## Building locally

The website can be built locally by cloning the repository and running
`./gradlew`. Gradle will install itself and the necessary
dependencies. You must have a working Java environment to run Gradle.

The build script creates two Docker containers, one to setup a Node.js
environment for running the Saxon-JS stylesheet compiler and another
to setup a web server for viewing the website locally.

After running the build, navigate to http://localhost:8484/i3w/ to
review the website locally. (If port 8484 conflicts with something else you have running locally,
edit `docker/docker-compose.yml` to change the port number.)

Experiment with the different systems by editing the source files
under `src/main` and then running the Gradle build again to update the
locally published versions.

### Building without Docker

If you don’t have Docker, you can tell run the build without it by
passing a parameter to the script:

```shell
./gradlew -Pskip_docker=true
```

If you do this, the compiled stylesheet is simply downloaded from the
published website. Any changes you make to the XSLT sources won’t be
reflected until you compile that stylesheet yourself.

You will also have to point a web server at the build directory
(`build/website`) in order to review the website locally. (You can
point to the files with `file:///` URIs, but beware that some browsers
on some platforms may impose security constraints that prevent the
scripting parts from working correctly.)
