Instructions (WIP)

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
export USERDIR="/home/binkocd"
export PUID="1000"
export PGID="1000"
deploy portainer
https://portainer.readthedocs.io/en/latest/deployment.html
copy over nzb.yml
deploy nzb stack
docker-compose -f nzb.yml -p nzb up -d
clone nzbtomeda to sab config folder (look for different location?)
https://github.com/clinton-hall/nzbToMedia
Configure SABNZBD