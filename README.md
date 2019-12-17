# Topoviz 
### A network topology visualizer 

Creates a force directed D3 graph based on the output from one of these JUNOS cli cmds:  

```show ospf database router extensive | display xml | no-more | save <file>```  
```show isis database extensive | display xml | no-more | save <file>```  
```show ted database extensive | display xml | no-more | save <file>```  


## INSTALLATION

### Recommended method is to use Docker:

  * Create a directory /tmp/topoviz, and a file named Dockerfile within it. Paste this into the file:  

```
FROM ubuntu:latest
MAINTAINER Juniper Networks
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
```

  * Create the docker image using ```docker build /tmp/topoviz/ -t topoviz:v0.1```
  * Run the docker image using ```docker run -itd -p 8080:80/tcp topoviz:v0.1```
  * Connect to host using http on  port 8080, example: http://localhost:8080/topoviz/  

### Alternatively you could:
  * Clone the repo onto a server running apache and php  
  * Ensure perl has List::MoreUtils installed  
  * Update the php.ini so that post_max_size = 100M and upload_max_filesize = 100M, restart apache  
  * Ensure the json directory is writeable by apache  
  

## USAGE

* Zoom using:
  * Mousewheel
  * Trackpad pinch/expand
  * Trackpad 2 finger drag up/down
* Click on a router to:
  * List its details in info pane
* Mouseover a router to:
  * Highlight connected nodes
* Drag any node to:
  * Fix its position
* Double click a fixed node to:
  * Release it
* Mouseover a link to:
  * Show its metric
  
  
## NOTES

This code was written in 2016 for JTAC, some customers have expressed an interest in the tool hence its wider release  

## LICENSE

Apache 2.0  

## CONTRIBUTORS

Juniper Networks is actively contributing to and maintaining this repo. Please contact jnpr-community-netdev@juniper.net for any queries.

*Contributors:*

[Chris Jenn](https://github.com/ipmonk)
