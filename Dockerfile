FROM ubuntu:latest
LABEL version="f9f6e2f-e"
LABEL maintainer="15333619+hsghost@users.noreply.github.com"
ENV APP_VERSION f9f6e2f
RUN apt-get update && export TZ=Asia/Shanghai && ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone && apt-get install -y libtag-extras-dev
ADD ncmdump.tar /ncmdump/
RUN dpkg -i /ncmdump/ncmdump.deb && rm -f /ncmdump/ncmdump.deb && chmod +x /ncmdump/ncmdump.sh
WORKDIR /ncmworking
ENTRYPOINT [ "/ncmdump/ncmdump.sh" ]
