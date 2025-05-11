#######################################################################################################
# IMAGE creation
#######################################################################################################
#
# Base the image on the latest version of alphine
FROM alpine:latest
#
LABEL maintainer="jvdzande"

#
# Install Apps. create directories and create Symlink lua to lua5.2
RUN apk add --no-cache bash tzdata php lua5.2 lua-socket lua-sec curl jq tini && \
	ln -s /usr/bin/lua5.2 /usr/bin/lua && \
	mkdir -p /dtgbotinit && \
	mkdir -p /dtgbot && \
	mkdir -p /data && \
	mkdir -p /modules


COPY ./app /dtgbot/
COPY ./_docker/*.sh /dtgbotinit/
RUN chmod +x /dtgbotinit/*sh

VOLUME "/modules"
VOLUME "/data"

ARG GIT_RELEASE
ENV GIT_RELEASE=${GIT_RELEASE}

WORKDIR /dtgbot
ENTRYPOINT ["tini", "--"]
CMD ["/dtgbotinit/startupdtgbot.sh"]
