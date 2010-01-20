# memcached mon

This is a tool I wrote for myself when working on something where I
needed to see what was happening at a very high resolution.

It's a hack, but I've had a couple people ask me about it, so I
figured I'd let them see how it works.

![memcached_mon](http://img.skitch.com/20100120-pex15eidumraeixhsfwsjjsqwn.png)

## Requirements

In order to do anything with this, you'll need a recent build of
[processing](http://processing.org/).

With that, you should just be able to open the .pde and start editing.

## Usage

The server IP address and port number and list of stats to view are
hard-coded.  The meters auto-layout so adding things to look at is
pretty easy, but you do have to edit the code to do anything useful.
