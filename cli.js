var argv = require('optimist')
            .default('dir', process.cwd())
            .argv;

require('coffee-script');
var ariel = require('./lib/ariel');

module.exports.run = function() {
  
  console.log("RUNNING:");

  ariel.watchDir( argv.dir );

  process.stdin.resume();
  require('tty').setRawMode(true);

  process.stdin.on('keypress', function(letter,key){
    
    if(key && key.ctrl & key.name === 'c'){
      process.exit();
    }

  });
}

