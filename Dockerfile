ARG target
FROM ${target}

ARG uid
RUN adduser -u "${uid}" user
USER user
WORKDIR /home/user

CMD ["/bin/bash", "/src/make_installer.sh"]
