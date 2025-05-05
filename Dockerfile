FROM ubuntu:24.04 AS install
ARG installer
RUN useradd --home /home/user --create-home --shell /bin/bash user
WORKDIR /home/user
USER user
ADD --chown=user ${installer} /home/user/installer.sh
RUN /home/user/installer.sh -q -p /home/user/timc && rm /home/user/installer.sh

FROM ubuntu:24.04 AS final
COPY --from=install /home/user/timc /home/user/timc
RUN echo 'export PATH="/home/user/timc/bin:$PATH"' >>/home/user/.bashrc
