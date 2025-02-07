# This Dockerfile is used to build an headless vnc image based on Centos

FROM centos:7

LABEL maintainer="Sal Tijerina <stijerina@tacc.utexas.edu>"

# ENV REFRESHED_AT 2018-10-29

# LABEL io.k8s.description="Headless VNC Container with Xfce window manager, firefox and chromium" \
#     io.k8s.display-name="Headless VNC Container based on Centos" \
#     io.openshift.expose-services="6901:http,5901:xvnc" \
#     io.openshift.tags="vnc, centos, xfce" \
#     io.openshift.non-scalable=true

## Connection ports for controlling the UI:
# VNC port:5901
# noVNC webport, connect via http://IP:6901/?password=vncpassword
ENV DISPLAY=:1 \
    VNC_PORT=5901 \
    NO_VNC_PORT=6080
# EXPOSE $VNC_PORT $NO_VNC_PORT
EXPOSE $NO_VNC_PORT

### Envrionment config
ENV HOME=/headless \
    TERM=xterm \
    STARTUPDIR=/dockerstartup \
    INST_SCRIPTS=/headless/install \
    NO_VNC_HOME=/headless/noVNC \
    VNC_COL_DEPTH=24 \
    VNC_RESOLUTION=1280x1024 \
    VNC_PW=vncpassword \
    VNC_VIEW_ONLY=false
WORKDIR $HOME

### Add all install scripts for further steps
COPY ./src/common/install/ $INST_SCRIPTS/
COPY ./src/centos/install/ $INST_SCRIPTS/
RUN find $INST_SCRIPTS -name '*.sh' -exec chmod a+x {} +

### Install some common tools
RUN $INST_SCRIPTS/tools.sh
ENV LANG='en_US.UTF-8' LANGUAGE='en_US:en' LC_ALL='en_US.UTF-8'

### Install xvnc-server & noVNC - HTML5 based VNC viewer
RUN $INST_SCRIPTS/tigervnc.sh
RUN $INST_SCRIPTS/no_vnc.sh

### Install firefox and chrome browser
RUN $INST_SCRIPTS/firefox.sh
RUN $INST_SCRIPTS/chrome.sh

### Install xfce UI
RUN $INST_SCRIPTS/xfce_ui.sh
COPY ./src/common/xfce/ $HOME/

### configure startup
RUN $INST_SCRIPTS/libnss_wrapper.sh
COPY ./src/common/scripts $STARTUPDIR
RUN $INST_SCRIPTS/set_user_permission.sh $STARTUPDIR $HOME

# RUN yum update && yum install -y \
#     python36 \
#     centos-release-scl

# RUN yum-config-manager --enable rhel-server-rhscl=7-rpms

# RUN yum install -y devtoolset-4

RUN yum install -y wget openssl sed &&\
    yum -y autoremove &&\
    yum clean all &&\
    wget http://nginx.org/packages/centos/7/x86_64/RPMS/nginx-1.14.0-1.el7_4.ngx.x86_64.rpm &&\
    rpm -iv nginx-1.14.0-1.el7_4.ngx.x86_64.rpm

COPY src/common/etc/nginx/ /etc/nginx/

# USER 1000

WORKDIR /root

ENTRYPOINT ["/dockerstartup/vnc_startup.sh"]
CMD ["--wait"]
