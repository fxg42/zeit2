
/**
 * Module dependencies.
 */

var coffee = require('coffee-script');
var expressnamespace = require('express-namespace');
var express = require('express');
var routes = require('./routes');
var http = require('http');
var path = require('path');
var mongodb = require('mongodb');

var app = express();

// all environments
app.set('port', process.env.PORT || 8888);
app.set('views', __dirname + '/views');
app.set('view engine', 'jade');
app.use(express.favicon());
app.use(express.logger('dev'));
app.use(express.bodyParser());
app.use(express.methodOverride());
app.use(app.router);
app.use(express.static(path.join(__dirname, 'public')));

// development only
if ('development' == app.get('env')) {
  app.use(express.errorHandler());
}

var manager = new mongodb.Db('timetrack', (new mongodb.Server('localhost', 27017, {auto_reconnect:true, poolSize:5})), {safe:true});

manager.open(function (err, db) {
  app.get('/', routes.index);
  require('./routes/frames')(app, db);

  http.createServer(app).listen(app.get('port'), function(){
    console.log('Express server listening on port ' + app.get('port'));
  });
});
