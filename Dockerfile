FROM ubuntu:24.04
ARG version platform
RUN useradd --home /home/user --create-home --shell /bin/bash user
WORKDIR /home/user
USER user
ADD --chown=user out/timc-installer-${version}-${platform}.sh /home/user/installer.sh
RUN /home/user/installer.sh -q -p /home/user/timc
RUN echo 'export PATH="/home/user/timc/bin:$PATH"' >>/home/user/.bashrc
RUN rm /home/user/installer.sh
