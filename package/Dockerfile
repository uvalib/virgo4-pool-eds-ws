FROM amazoncorretto:17-alpine3.17

# add necessary packages
RUN apk update && apk upgrade && apk --no-cache add bash tzdata build-base ca-certificates git && rm -rf /var/cache/apk/*

# install jruby
ADD .ruby-version /tmp
RUN apk --no-cache add jruby=~$(cat /tmp/.ruby-version | awk -F- '{print $2}')
ENV PATH $PATH:/usr/share/jruby/bin

# create the run user and group
RUN addgroup --gid 18570 sse && adduser --uid 1984 docker -G sse -D

# set the timezone appropriatly
ENV TZ=UTC
RUN cp /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

# specify home
ENV APP_HOME /pool-eds-ws
WORKDIR $APP_HOME

# copy the Gemfile into the image and temporarily set the working directory to where they are.
ADD Gemfile Gemfile.lock .ruby-gemset ./
RUN rm -rf tmp/cache/*

# add necessary gems
RUN jgem install bundler -v 2.1.4

# see: https://github.com/jruby/jruby/issues/6475
ENV JAVA_OPTS="--add-opens java.base/sun.nio.ch=ALL-UNNAMED --add-opens java.base/java.io=ALL-UNNAMED"

# bundle
RUN bundle install --jobs=4 --without=["development" "test"] --redownload

# install the app
COPY . $APP_HOME

# update permissions
RUN chown -R docker $APP_HOME && chgrp -R sse $APP_HOME

# define port and startup script
EXPOSE 8080
CMD scripts/entry.sh

# move in the profile
COPY data/container_bash_profile /home/docker/.profile

# Add the build tag
ARG BUILD_TAG
RUN test -n "$BUILD_TAG" && touch $APP_HOME/buildtag.build-$BUILD_TAG || touch $APP_HOME/buildtag.build-0

# specify the user
USER docker

#
# end of file
#
