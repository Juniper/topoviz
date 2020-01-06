FROM ubuntu:latest
ENV TZ=Etc/UTC
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone
RUN apt-get update
RUN apt-get install -y --no-install-recommends apache2 git make gcc php libc6-dev ca-certificates
RUN PERL_MM_USE_DEFAULT=1 cpan install List::MoreUtils
RUN sed -i 's/upload_max_filesize = 2M/upload_max_filesize = 100M/' /etc/php/*/apache2/php.ini
RUN sed -i 's/post_max_size = 8M/post_max_size = 100M/' /etc/php/*/apache2/php.ini
RUN cd /var/www/html && git clone https://github.com/Juniper/topoviz.git
RUN chown -R www-data:www-data /var/www/html/topoviz/*
EXPOSE 80
CMD apachectl -D FOREGROUND
