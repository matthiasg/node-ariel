var argv = require('optimist')
            .default('dir', process.cwd())
            .argv;

var ariel = require('./ariel');

module.exports.run = function() {
  ariel.watchDir( argv.dir );
}

