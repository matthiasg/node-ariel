(function() {
  var CoffeeScript, compileToJavascript, convertToJavascriptExtension, enumerateAllFiles, file, fs, getCoffeeScriptOptions, isCoffeeScriptFile, isCompiledJavascriptFileForMatchingCoffeeScript, isMatchedByAny, isNewer, options, path;

  fs = require('fs');

  path = require('path');

  file = require('file');

  CoffeeScript = require('coffee-script');

  module.exports.options = options = {
    excludeDirs: ['.git.*', 'bin.*', 'test.*', 'node_modules.*']
  };

  module.exports.test = function() {
    return true;
  };

  module.exports.watchDir = function(dirPath) {
    if (!path.existsSync(dirPath)) {
      console.log("Cannot watch '" + dirPath + "'. Directory does not exist.");
      return;
    }
    console.log("watching dir: " + dirPath);
    return enumerateAllFiles(dirPath, options.excludeDirs, function(dirPath, file) {
      if (isCoffeeScriptFile(file)) compileToJavascript(file);
      if (isCompiledJavascriptFileForMatchingCoffeeScript) {}
    });
  };

  enumerateAllFiles = function(rootDirPath, excludeDirs, callbackPerFile) {
    return file.walk(rootDirPath, function(unknown, dirPath, dirs, files) {
      var dirName;
      dirName = path.relative(rootDirPath, dirPath);
      if (isMatchedByAny(dirName, excludeDirs)) return;
      return files.forEach(function(filePath) {
        return callbackPerFile(dirPath, filePath);
      });
    });
  };

  isMatchedByAny = function(str, matchers) {
    var m, _i, _len;
    for (_i = 0, _len = matchers.length; _i < _len; _i++) {
      m = matchers[_i];
      if (str.match(m)) return true;
    }
    console.log("not skipping " + str);
    return false;
  };

  compileToJavascript = function(filePath) {
    var code, javascriptFilePath, js;
    javascriptFilePath = convertToJavascriptExtension(filePath);
    if (path.existsSync(javascriptFilePath)) {
      if (isNewer(javascriptFilePath, filePath)) return;
    }
    console.log("compiling " + filePath + " -> " + javascriptFilePath);
    code = fs.readFileSync(filePath).toString();
    js = CoffeeScript.compile(code);
    return fs.writeFileSync(javascriptFilePath, js);
  };

  isNewer = function(a, b) {
    var aStats, bStats;
    aStats = fs.statSync(a);
    bStats = fs.statSync(b);
    return aStats.mtime.getTime() > bStats.mtime.getTime();
  };

  getCoffeeScriptOptions = function(filePath) {
    return {
      filename: filePath,
      source: filePath,
      bare: false
    };
  };

  isCoffeeScriptFile = function(filePath) {
    return path.extname(filePath) === '.coffee';
  };

  isCompiledJavascriptFileForMatchingCoffeeScript = function(filePath) {
    return false;
  };

  convertToJavascriptExtension = function(filePath) {
    var dirname, nameWithoutExtension, oldExtension;
    dirname = path.dirname(filePath);
    oldExtension = path.extname(filePath);
    nameWithoutExtension = path.basename(filePath, oldExtension);
    return path.join(dirname, nameWithoutExtension + ".js");
  };

}).call(this);
