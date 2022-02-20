FROM python:alpine as base
ENV PIP_NO_CACHE_DIR=1 S6_SERVICES_GRACETIME=300000 S6_CMD_WAIT_FOR_SERVICES_MAXTIME=5000000
COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
COPY install-s6.sh /tmp/install-s6.sh
RUN mkdir -p /var/www \
    && mkdir /docker-entrypoint.d \
    && apk add --no-cache bash curl gawk unit wget \
    && chown -R unit:unit /var/www \
    && ln -sf /dev/stdout /var/log/unit.log \
    && ln -sf /dev/stdout /var/log/access.log \
    && /tmp/install-s6.sh \
    && rm /tmp/install-s6.sh

FROM base
RUN wget -P /opt  https://github.com/sycured/xml2json/raw/master/xml2json.py \
    && chmod +x /opt/xml2json.py \
    && pip install defusedxml \
    && bash -c "mkdir -p  /etc/s6-overlay/s6-rc.d/{cron,nginx}" \
    && echo -e "#!/bin/bash\nexec crond -f" > /etc/s6-overlay/s6-rc.d/cron/run \
    && chmod +x /etc/s6-overlay/s6-rc.d/cron/run \
    && echo -e "#!/bin/bash\nexec unitd --no-daemon --control unix:/var/run/control.unit.sock" >  /etc/s6-overlay/s6-rc.d/nginx/run \
    && chmod +x /etc/s6-overlay/s6-rc.d/nginx/run \
    && echo "longrun" > /etc/s6-overlay/s6-rc.d/cron/type \
    && echo "longrun" > /etc/s6-overlay/s6-rc.d/nginx/type \
    && echo "de" > /etc/s6-overlay/s6-rc.d/nginx/dependencies \
    && mkdir /etc/s6-overlay/s6-rc.d/de \
    && echo "oneshot" > /etc/s6-overlay/s6-rc.d/de/type \
    && echo "exec bash -c '/usr/local/bin/docker-entrypoint.sh'" > /etc/s6-overlay/s6-rc.d/de/up \
    && touch /etc/s6-overlay/s6-rc.d/user/contents.d/nginx \
    && touch /etc/s6-overlay/s6-rc.d/user/contents.d/cron \
    && echo '{"listeners":{"*:8000":{"pass":"routes"}},"routes":[{"action":{"share":"/var/www$uri"}}]}' > /docker-entrypoint.d/config.json \
    && echo -e "#!/bin/bash\nexec /etc/periodic/15min/dl_and_convert" > /docker-entrypoint.d/dl_at_boot.sh \
    && chmod +x /docker-entrypoint.d/dl_at_boot.sh \
    && echo -e "#!/bin/bash\ncurl -X PUT -d '\"/var/log/access.log\"' --unix-socket /var/run/control.unit.sock http://localhost/config/access_log" > /docker-entrypoint.d/set_access_log.sh \
    && chmod +x /docker-entrypoint.d/set_access_log.sh \
    && echo -e "#!/bin/bash\ncd /var/www\nwget -N https://xmltv.ch/xmltv/xmltv-tnt.xml 2>&1 | awk '/saved/ {system(\"/opt/xml2json.py xmltv-tnt.xml > xmltv-tnt.json\")}'\nexec chown unit:unit xmltv-tnt.json xmltv-tnt.xml" > /etc/periodic/15min/dl_and_convert \
    && chmod +x /etc/periodic/15min/dl_and_convert

EXPOSE 8000
ENTRYPOINT ["/init"]