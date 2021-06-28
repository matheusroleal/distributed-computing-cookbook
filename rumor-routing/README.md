# Rumor Routing

Advances in microsensor technology will enable the implementation of services for a wide range of applications. In order to limit communication overhead, dense sensor networks require new, highly efficient methods for distributing queries to nodes that observed interesting events in the network. A highly efficient data-centric routing mechanism will offer lower energy costs and improve network longevity. Furthermore, because of the large amount of system and redundancy, data becomes disassociated from the specific node and resides in regions of the network. 

<br>

This work aims to develop a rumor routing simulator using the Message Queuing Telemetry Transport protocol and LÖVE. This is a lightweight messaging protocol for sensors and small mobile devices optimized for TCP/IP networks.

## MQTT

MQTT is a publish/subscribe model based, "lightweight" messaging protocol over TCP/IP for communication between "Internet of Things" devices such as ESP8266, Raspberry Pi, etc. It is very popular with low resources and battery powered applications such as home automation, security alarm systems and battery-powered sensor networks. 

Mosquitto is an open source message broker (or server) that implements MQTT protocols. With its good community support, documentation, and ease of installation it has become one of the most popular MQTT brokers. To install it please read the [official documentation](https://github.com/eclipse/mosquitto#installing).

## LÖVE

LÖVE is an awesome framework you can use to make 2D games in Lua. It's free, open-source, and works on Windows, macOS, Linux, Android, and iOS.Download the latest version of LÖVE from the website, and install it. If you're on Windows and don't want to install LÖVE, you can also just download the zipped executables and extract them anywhere. To find out which version of LÖVE is installed, follow the [official documentation](https://love2d.org/wiki/Getting_Started).

## How to run
Use one of the scripts created. For a 4 nodes enviroment just run:
```
make test-4-nodes-enviroment
```

If you prefer more nodes, just run:
```
make test-9-nodes-enviroment
```