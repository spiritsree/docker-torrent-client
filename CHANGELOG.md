# Chanelog

## Version 0.0.3

* Customizing transmission options using config file (move from commandline options)
* Use dockerize to exand config templates using env variables
* Logging from both openvpn and transmission to log file in data dir with optional switchback

**Bug Fix**

* Fix mknod syntax in alpine


## Version 0.0.2

* Utilize mounted dir for keeping data
* Logs to file in data dir

## Version 0.0.1

* Initial MVP
* Dockerfile support for ubuntu and alpine
* OpenVPN with free hideme server support
* Transmission client with basic config
* Basic setup script to build docker image and the run command to execute
