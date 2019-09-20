FROM neo4j:3.4.5-enterprise

RUN apk add curl python2

USER neo4j
RUN curl -sSL https://sdk.cloud.google.com | bash
ENV PATH $PATH:/var/lib/neo4j/google-cloud-sdk/bin

RUN mkdir /var/lib/neo4j/backup
RUN mkdir /var/lib/neo4j/scripts

ADD --chown=neo4j backup.sh /var/lib/neo4j/scripts/backup.sh
RUN chmod +x /var/lib/neo4j/scripts/backup.sh

ENTRYPOINT ["/var/lib/neo4j/scripts/backup.sh"]
