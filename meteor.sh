lsb_release -a #check linux Version - 10.04 (lucid) expected
passwd #change password

#set all languages properly
export LANGNAME="en_US.UTF-8"
locale-gen $LANGNAME
export LC_ALL=$LANGNAME
export LC_CTYPE=$LANGNAME
export LANG=$LANGNAME
export LANGUAGE=$LANGNAME
update-locale LC_ALL=$LANGNAME
update-locale LC_CTYPE=$LANGNAME
update-locale LANG=$LANGNAME
update-locale LANGUAGE=$LANGNAME
mkdir /data/ #web root
mkdir /data/db/ #mongodb dir
mkdir /data/websites/ #web dir
mkdir /data/logs/ #log dir

#update apt & remove apache (only one can listen on port 80 - change apache port and add rules to proxy if u want to use apache)
apt-get update
apt-get remove -y apache2 apache2-doc apache2-mpm-prefork apache2-utils apache2.2-bin apache2.2-common

#add some repositories and install some basic tools
apt-get -y install nano curl git-core python-software-properties
add-apt-repository ppa:ubuntu-toolchain-r/test
echo "
  deb     http://us.archive.ubuntu.com/ubuntu/ lucid main restricted
  deb-src http://us.archive.ubuntu.com/ubuntu/ lucid main restricted
  deb     http://us.archive.ubuntu.com/ubuntu/ lucid-updates main restricted
  deb-src http://us.archive.ubuntu.com/ubuntu/ lucid-updates main restricted
  deb     http://us.archive.ubuntu.com/ubuntu/ lucid universe
  deb-src http://us.archive.ubuntu.com/ubuntu/ lucid universe
  deb     http://us.archive.ubuntu.com/ubuntu/ lucid-updates universe
  deb-src http://us.archive.ubuntu.com/ubuntu/ lucid-updates universe
  deb     http://us.archive.ubuntu.com/ubuntu/ lucid multiverse
  deb-src http://us.archive.ubuntu.com/ubuntu/ lucid multiverse
  deb     http://us.archive.ubuntu.com/ubuntu/ lucid-updates multiverse
  deb-src http://us.archive.ubuntu.com/ubuntu/ lucid-updates multiverse
  deb     http://archive.canonical.com/ubuntu lucid partner
  deb-src http://archive.canonical.com/ubuntu lucid partner
  deb     http://security.ubuntu.com/ubuntu lucid-security main restricted
  deb-src http://security.ubuntu.com/ubuntu lucid-security main restricted
  deb     http://security.ubuntu.com/ubuntu lucid-security universe
  deb-src http://security.ubuntu.com/ubuntu lucid-security universe
  deb     http://security.ubuntu.com/ubuntu lucid-security multiverse
  deb-src http://security.ubuntu.com/ubuntu lucid-security multiverse
" >> /etc/apt/sources.list
apt-get update
apt-get -y -q -qq upgrade
apt-get -y install gcc-4.6 g++-4.6

#download & install nvm (node version manager)
git clone git://github.com/creationix/nvm.git ~/.nvm
~/.nvm/install-gitless.sh
[[ -s /root/.nvm/nvm.sh ]] && . /root/.nvm/nvm.sh # This loads NVM
nvm install 0.10.18

#install meteor and some basic node packages
curl https://install.meteor.com | /bin/sh
npm install -g meteorite
npm install -g forever
npm install -g coffee-script
npm install -g http-proxy

# --- sync with github
#generate ssh key to download private git repositories
ssh-keygen -t rsa -C "dev@zaku.eu"

cat ~/.ssh/id_rsa.pub

#[external] enter ssh-public key into github

#download websites & proxy (master branch)
git clone git@github.com:Zaku-eu/websites.git /data/websites/

# --- sync with dropbox

wget -O /bin/dropbox.py "http://www.dropbox.com/download?dl=packages/dropbox.py"
chmod +x /bin/dropbox.py
dropbox.py start -i

lynx https://www.dropbox.com/cli_link?host_id=[guid]

dropbox.py autostart y

rm /data/websites -r
ln -s ~/Dropbox/websites/ /data/

#register upstart script
echo "
  #/etc/init/meteor-proxy.conf
  start on (local-filesystems)
  stop on shutdown

  respawn

  script
  exec 2>>/data/logs/upstart.log
    set -x
    cd /data/websites/proxy/
    export HOME=/root/
    export PATH=$PATH
    exec coffee /data/websites/proxy/proxy.coffee >> /data/logs/proxy.log
  end script" >> /etc/init/meteor.conf

rm /etc/init/meteor.conf #remove upstart script
/sbin/start meteor       #start upstart script (once)
/sbin/stop meteor        #stop upstart script (till reboot)

#delete logfiles
rm /data/logs/upstart.log
rm /data/logs/proxy.log