# trm2rinex docker image for Trimble convertToRinex utility use on Linux

## Introduction

This repository provides material and instructions to build a docker image that packages the Trimble [convertToRinex](https://geospatial.trimble.com/trimble-rinex-converter) utility together with a minimal [Wine](https://www.winehq.org/) setup, allowing to run the native Windows only software on a Linux x86 based system. Final image is around 300MB

The Trimble utility can be found at official Trimble page : https://geospatial.trimble.com/trimble-rinex-converter

**For intellectual property reasons, unless Trimble provides me with a written authorization to do so, I will not provide a pre-build docker image because it would contain the Trimble binaries and I'm not explicitely allowed to redistribute them.
Even if no specific license terms are displayed on Trimble page or when installing the software manually on a regular Windows machine.**

The image has been successfully built and tested using [Wine 6.22](https://github.com/wine-mirror/wine/commit/986254d6c17ee1e5fb3aed6effcf2766bf1e787e) release and the following Trimble required binaries for version 3.14 of Trimble [convertToRinex](https://geospatial.trimble.com/trimble-rinex-converter) :

- https://dl.trimble.com/osg/survey/gpsconfigfiles/21.9.27/trimblecfgupdate.exe
- https://trl.trimble.com/dscgi/ds.py/Get/File-869391/convertToRinex314.msi

If they are still available at time you build the image, then they will be downloaded and used automatically. Otherwise you may need to get the manually from another source and modify the Dockerfile around lines 213 and 214 to change the source of the files.

## Quick start : building the image

Retrieve the repository and build the docker image with command:

```bash
docker build -t yourreponame/trm2rinex:cli-light .
```

You can change the repo (or even omit it), image name and tag to whatever you want.

The image build has 3 stages :

- stage 1 : a minimal [Wine 6.22](https://github.com/wine-mirror/wine/commit/986254d6c17ee1e5fb3aed6effcf2766bf1e787e) build (from source).
- stage 2 : download and installation of the Trimble binaries, cleanup of the filesystem to have a light final stage image.
- stage 3 : final image build stage.

Image build time will take some time (about 10 minutes on my computer) and will need a few gigs af space on the hard drive (about 3GB for the stage 1 Wine source code build stage, 900MB for the stage 2 and 300MB for final image

You can modify the build command to prevent caching intermediate stages:

```bash
docker build --no-cache -t yourreponame/trm2rinex:cli-light .
```

This will save some space, but you'll have to rebuild from scratch each time you modify the Dockerfile.

## Image customization

A few variables at the beginning of Dockerfile allows some customization. Here they are with some details about what they do.

| Variable               | Description |
| --- | --- |
|`USER_NAME`             | name of the non-root user inside the container (user is created with sudo rights) |
|`USER_PASSWD`           | password of that user |
|`USER_UID`              | id of the user inside the container which may ideally be matched to the id of user on docker host in order to remove file access persmission issues.<br/>Default to 1000 which is the the id of the main user on my desktop ubuntu setup |
|`USER_GID`              | same idea as for `USER_UID` but for group id.<br/>Defaults to 100 which is the id of *users* group on many distributions |
|`MAKE_JN`               | number of build cores used to compile Wine. Adapt to the computer where you'll build the image |
|`DELAY_BETWEEN_INSTALL` | this value in seconds is used to wait between some wine calls at stage 2 when installing the Windows binaries.<br/>I noticed that a wait is needed in order to let wineserver and other wine process terminate cleanly.<br/>You may need to increase this value on slow machines |

## Usage

Here are a few possible use case examples:

- Display usage details (docker and original Trimble convertToRienx command line options)

```bash
docker run --rm yourreponame/trm2rinex:cli-light
```

- Provide an interactive shell inside the container (mostly for debug and inspection purposes)
```bash
docker run -it --rm yourreponame/trm2rinex:cli-light /bin/bash
```

- Converts the Trimble proprietary format file MAGC320b.2021.rt27 (which for this example is assumed to be located on the current directory) into RINEX 3.04 version files.  
For actual conversion use cases, it is requiered to map volumes with read permission (**for the container user**) at the input file location, and write permission (**for the container user**) at the output files location.  

   - `data/MAGC320b.2021.rt27` defines the input file (relative to container filesystem root)  
   - `-p data/out` defines the path for the conversion output (relative to container filesystem root)  
   - `-n` to **NOT** perform height reference point corrections
   - `-d` to include doppler observables in the output observation file
   - `-co` to include clock corrections in the output observation file
   - `-s` to include signal strength values in the output observation file
   - `-v 3.04` to choose which RINEX version is generated (cf. command line usage for details)  
   - `-h 0.1387` to include the marker to antenna ARP vertical offset into RINEX header

```bash
docker run --rm -v "$(pwd):/data" yourreponame/trm2rinex:cli-light data/MAGC320b.2021.rt27 -p data/out -n -d -co -s -v 3.04 -h 0.1387
```  

- as stated above, path are relative to the container root filesystem, and you can also use them with a Windows like syntax remembering that the filesystem root `/` is mapped to `Z:\`for Wine path, and that you need to escape character `\` as `\\` in commands. The following commands are therefore also valid with alternative path syntax (additionnal options removed for focus on path).

```bash
docker run --rm -v "$(pwd):/data" yourreponame/trm2rinex:cli-light Z:\\data\\MAGC320b.2021.rt27 -p Z:\\data\\out
docker run --rm -v "$(pwd):/data" yourreponame/trm2rinex:cli-light Z:/data/MAGC320b.2021.rt27 -p Z:/data/out
```

- Performs the conversion with a file based set of options which allow for a more complete control of the conversion (cf. command line usage for details)

```bash
docker run --rm -v "$(pwd):/data" yourreponame/trm2rinex:cli-light data/MAGC320b.2021.rt27 -p data/out @data/magc-rinex304.settings
```

## Test runs, output comparaison and performances benchmark vs. native Windows based tool

`test_run_results` subdirectory from the repository contains the conversion outputs of the provided MAGC320b.2021.rt27 file performed with convertToRinex version 3.14 runned natively on a Windows 10 Pro computer or the docker container executed from an Ubuntu 21.10 Desktop install (same dual boot i9-9880H based computer)

- Rinex 2.11 : Windows 10 Pro native conversion
```DOS
cmd /v:on /c "echo !time! && "C:\Program Files (x86)\Trimble\convertToRINEX\convertToRinex.exe" C:\GNSS\test\MAGC320b.2021.rt27 -p C:\GNSS\test\out_211_native\ @C:\GNSS\test\magc-rinex211.settings && echo !time!"
```
```console
12:37:28.26
Analyse C:\GNSS\test\MAGC320b.2021.rt27... Terminé.
Conversion en cours MAGC320b.2021.rt27... Succès
12:37:34.89
```

- Rinex 3.04 : Windows 10 Pro native conversion
```DOS
cmd /v:on /c "echo !time! && "C:\Program Files (x86)\Trimble\convertToRINEX\convertToRinex.exe" C:\GNSS\test\MAGC320b.2021.rt27 -p C:\GNSS\test\out_304_native\ @C:\GNSS\test\magc-rinex304.settings && echo !time!"
```
```console
12:36:48.11
Analyse C:\GNSS\test\MAGC320b.2021.rt27... Terminé.
Conversion en cours MAGC320b.2021.rt27... Succès
12:36:55.76
```

- Rinex 2.11 : Ubuntu 21.10 + Docker conversion
```bash
time docker run --rm -v "$(pwd):/data" mathieupeyrega/trm2rinex:cli-light data/MAGC320b.2021.rt27 -p data/test_run_results/out_211_docker @data/magc-rinex211.settings
```
```console
Scanning data/MAGC320b.2021.rt27...Complete!
Converting MAGC320b.2021.rt27...Success 

real	0m17,287s
user	0m0,018s
sys	0m0,024s
```

- Rinex 3.04 : Ubuntu 21.10 + Docker conversion
```bash
time docker run --rm -v "$(pwd):/data" mathieupeyrega/trm2rinex:cli-light data/MAGC320b.2021.rt27 -p data/test_run_results/out_304_docker @data/magc-rinex304.settings
```
```console
Scanning data/MAGC320b.2021.rt27...Complete!
Converting MAGC320b.2021.rt27...Success 

real	0m19,091s
user	0m0,021s
sys	0m0,018s
```
- Benchmarks show a rough x3 time increase factor with the Docker+Wine solution, but it's the only solution I know about in order to convert to RINEX Trimble proprietary format with a vendor based tool from a Linux based operating system.

|OS|Conversion type|Time|
|---|---|---|
|Windows 10 Pro|RINEX 2.11|6.63s|
|Ubuntu 21.10|RINEX 2.11|17.3s|
|Windows 10 Pro|RINEX 3.04|7.65s|
|Ubuntu 21.10|RINEX 3.04|19.1s|

- Comparisons of result files shows that only the run date in the headers differs which validates the conversion:

```bash
diff test_run_results/out_211_native/MAGC320b.2021.21o test_run_results/out_211_docker/MAGC320b.2021.21o
```
```console
2c2
< cnvtToRINEX 3.14.0  trm2rinex-docker    20211123 113731 UTC PGM / RUN BY / DATE 
---
> cnvtToRINEX 3.14.0  trm2rinex-docker    20211123 131646 UTC PGM / RUN BY / DATE 
```
```bash
diff test_run_results/out_304_native/MAGC320b.2021.21o test_run_results/out_304_docker/MAGC320b.2021.21o
```
```console
2c2
< cnvtToRINEX 3.14.0  trm2rinex-docker    20211123 113651 UTC PGM / RUN BY / DATE 
---
> cnvtToRINEX 3.14.0  trm2rinex-docker    20211123 131718 UTC PGM / RUN BY / DATE
```

## Known issues

I tried and failed running this image on some Synology NAS through Synology provided Docker package.  
Tested equipement where :
- [RS3617xs+](https://global.download.synology.com/download/Document/Hardware/DataSheet/RackStation/17-year/RS3617xs+/fre/Synology_RS3617xs_Plus_Data_Sheet_fre.pdf)
- [SA3600](https://global.download.synology.com/download/Document/Hardware/DataSheet/SA/20-year/SA3600/enu/Synology_SA3600_Data_Sheet_enu.pdf)

both devices were equipped with 32GB of RAM and running DSM 7.0.1. While possible to get a bash prompt and run usual Linux commands without issue, any "wine" call hang forever.:

## Wish list

In case some Trimble folks are reading these lines, I'd love if they could make this repository obsolete by providing command line versions of their tools for various operating systems and architectures (x86, x86_64, ARM, ARM64).  
Other wishes to Trimble:
- Add an option to set a start and/or time (trimming away extra-data)
- Mixed navigation output for RINEX 3.xx
- Rinex 3.xx conventions auto naming scheme
- Provide a decent documentation for the command line options (e.g. for the antenna height corrections)

## Credits and License

- download_mono.sh script is almost copied from https://github.com/scottyhardy/docker-wine/blob/master/download_gecko_and_mono.sh
and therefore licensed under the same MIT terms as well as the rest of this repository.

- [Trimble convertToRinex](https://geospatial.trimble.com/trimble-rinex-converter) software is a property of Trimble company.


