FROM ubuntu:latest
MAINTAINER Juniper Networks, Inc
ENV TZ=Etc/UTC
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone
RUN apt-get update
RUN apt-get install -y --no-install-recommends apache2 git make gcc libc6-dev ca-certificates python3
RUN PERL_MM_USE_DEFAULT=1 cpan install List::MoreUtils
RUN cd /var/www/html && git clone https://github.com/Juniper/topoviz.git
RUN mv /var/www/html/topoviz/000-default.conf /etc/apache2/sites-available/000-default.conf
RUN a2enmod cgi
RUN chown -R www-data:www-data /var/www/html/topoviz/*
EXPOSE 80
CMD apachectl -D FOREGROUND
