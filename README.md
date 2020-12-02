# Topoviz 
### A network topology visualizer 

Creates a force directed D3 graph based on the output from one of these JUNOS cli cmds:  

```show ospf database router extensive | display xml | no-more | save <file>```  
```show isis database extensive | display xml | no-more | save <file>```  
```show ted database extensive | display xml | no-more | save <file>```  


## INSTALLATION

### Recommended method is to use Docker:

  * Clone the repo  
  * Create the docker image using ```docker build topoviz/ -t topoviz:v0.1```
  * Run the docker image using ```docker run -itd -p 8080:80/tcp topoviz:v0.1```
  * Connect to host using http on port 8080, example: http://localhost:8080/topoviz/  

### Alternatively you could:
  * Clone the repo onto a server running apache and the wsgi module
  * Ensure perl has List::MoreUtils installed  
  * Ensure the json directory is writeable by the apache user  
  

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
