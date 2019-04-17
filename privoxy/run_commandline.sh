#!/bin/sh

docker run -d --restart unless-stopped --name privoxy -p 8118:8118 charleswan/privoxy
