<h1 align="center">Welcome to Josh's Personal Docker Project(s) 👋</h1>
<p>
</p>

> A collection of Docker related scripts, configs, how-to's, and whatever else comes up along the way. 

## Install & Usage

```
Update Packages
Install zsh and nfs
sudo apt install zsh nfs-common
install ohmyzsh
install docker
https://www.digitalocean.com/community/tutorials/how-to-install-and-use-docker-on-ubuntu-20-04
install docker-compose
https://docs.docker.com/compose/install/
create app directories
mkdir -p {sabnzbd,nzbhydra2,sonarr,radarr,mylar,lazylibrarian,calibre-web,lidarr,ombi,heimdall}
create shared directory
mkdir shared
mount nfs
<NFS_SERVER_IP>:/<NFS_SHARE> <PATH/TO/>docker/shared nfs auto,nofail,noatime,nolock,intr,tcp,actimeo=1800 0 0
verify shared directory permissions
change timezone
set env variables
export TZ="America/Los_Angeles"
export USERDIR="/home/$USER"
export PUID="1000"
export PGID="1000"
deploy portainer
https://portainer.readthedocs.io/en/latest/deployment.html
deploy nzb stack
docker-compose -f nzb.yml -p nzb up -d
Configure SABNZBD
```

## Author

👤 **binkocd**

* Github: [@binkocd](https://github.com/binkocd)
* LinkedIn: [@joshuarobertbailey](https://linkedin.com/in/joshuarobertbailey)
