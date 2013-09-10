Zeit
================================================================================

Simple time tracking utility.

Setting up and running
--------------------------------------------------------------------------------

```
mongo> use timetrack;
mongo> db.createCollection('frames');
mongo> db.frames.insert({user:'default', frames:[]})

$ npm install coffee-script --global
$ npm install
$ grunt
$ node app.js
```
