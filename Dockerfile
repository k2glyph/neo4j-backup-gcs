FROM neo4j:3.4.5-enterprise

RUN apk add curl python2

RUN curl -sSL https://sdk.cloud.google.com | bash
ENV PATH $PATH:/root/google-cloud-sdk/bin

RUN mkdir /backup
RUN mkdir /scripts

ADD backup.sh /scripts/backup.sh
RUN chmod +x /scripts/backup.sh

CMD ["/scripts/backup.sh"]
