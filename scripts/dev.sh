#!/usr/bin/env bash

# run the server
jruby --debug -S bundle exec rackup -o 0.0.0.0 -p 8080
