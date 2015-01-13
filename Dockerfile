# VERSION:        0.1.7
# AUTHOR:         Daniel Mizyrycki <daniel@docker.com>
# DESCRIPTION:    Deploy docker-status container on GoogleAppEngine
# URLS:           stashboard page:       http://docker-status.appspot.com
# COMMENTS:
#     CONFIG_JSON is an environment variable json string loaded as:
#
#     export CONFIG_JSON='
#         { "GOOGLE_EMAIL":       "Google_account_email",
#           "GOOGLE_PASSWORD":    "Google_password",
#           "CONSUMER_KEY":       "Oauth_consumer_key",
#           "CONSUMER_SECRET":    "Oauth_consumer_secret",
#           "OAUTH_KEY":          "Oauth_key_for_GAE",
#           "OAUTH_SECRET":       "Oauth_secret_for_GAE" }'
#
# TO_BUILD:   docker build -t docker-status -rm .
# TO_DEPLOY:  docker run -e CONFIG_JSON="${CONFIG_JSON}" docker-status
# LOCAL_USAGE:
#   docker run  -p 8080:8080 -p 8000:8000 -i -t docker-status bash
#   /application/google_appengine/dev_appserver.py --skip_sdk_update_check \
#     --host 0.0.0.0 --port 8080 --admin_host 0.0.0.0 \
#     /application/stashboard/app.yaml

DOCKER-VERSION 0.7

# Base docker image
FROM ubuntu:precise
MAINTAINER Daniel Mizyrycki <daniel@docker.com>

ENV APP_PATH /application/stashboard
ENV PYTHONPATH $APP_PATH

RUN echo 'deb http://archive.ubuntu.com/ubuntu precise main universe' > \
  /etc/apt/sources.list
RUN apt-get update -q
RUN yes 'Yes, do as I say!' | apt-get remove -y --force-yes python2.7-minimal
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y less wget bzip2 \
  unzip ca-certificates vim
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y python-pip
RUN pip install --install-option="--install-lib=/usr/lib/python2.7" requests \
  oauth2 pyyaml pexpect

# Install stashboard and its dependencies
RUN mkdir /application; cd /application; \
  wget -q http://googleappengine.googlecode.com/files/google_appengine_1.8.8.zip; \
  unzip -q /application/google_appengine_1.8.8.zip; rm google_appengine_1.8.8.zip
RUN cd /application; wget -q -O - http://github.com/twilio/stashboard/tarball/master | \
  tar -zx --transform 's/[^\/]*/stashboard/'

RUN mv $APP_PATH $APP_PATH~
RUN cd /application; mv stashboard~/stashboard .;rm -rf stashboard~

# Add stashboard customization and deployment
ADD docker_status $APP_PATH
RUN mv $APP_PATH/deploy.py /usr/bin

CMD ["/usr/bin/deploy.py"]
