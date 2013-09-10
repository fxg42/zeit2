Zeit
================================================================================

Simple time tracking utility.

Setting up and running
--------------------------------------------------------------------------------

```
mongo> use timetrack;
mongo> db.createCollection('frames');
mongo> db.frames.insert({user:'default', frames:[]})

$ npm install -g coffee-script
$ npm install -g grunt-cli

$ npm install
$ grunt
$ node app.js
```
