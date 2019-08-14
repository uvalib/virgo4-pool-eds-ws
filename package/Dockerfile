FROM alpine:3.10

# add necessary packages
RUN apk update && apk upgrade && apk add bash tzdata build-base ca-certificates git

# install java 11 JDK
RUN apk --no-cache add openjdk11 --repository=http://dl-cdn.alpinelinux.org/alpine/edge/community

# install jruby
RUN apk --no-cache add jruby

# create the run user and group
RUN addgroup --gid 18570 sse && adduser --uid 1984 docker -G sse -D

# set the timezone appropriatly
ENV TZ=UTC
RUN cp /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

# add necessary gems
RUN jgem install bundler
ENV PATH $PATH:/usr/share/jruby/bin

# specify home 
ENV APP_HOME /pool-eds-ws
WORKDIR $APP_HOME

# copy the Gemfile into the image and temporarily set the working directory to where they are.
ADD Gemfile Gemfile.lock .ruby-gemset ./
#ADD Gemfile .ruby-gemset ./
RUN rm -rf tmp/cache/*

# bundle
RUN bundle install --jobs=4 --without=["development" "test"] --force

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
