(function() {
  var CoffeeScript, changeExtension, changeToCoffeeScriptExtension, changeToJavascriptExtension, child, cleanAllCompiledFilesOnProcessExit, cleanupFile, compilationRequests, compileAllFiles, compileCoffeeScriptFileToJavascriptFile, compileFile, compileToJavascript, enumerateAllFiles, file, filesToCleanup, fs, getCoffeeScriptOptions, handleAllFiles, handleCompileRequests, handleDetectedFile, handleTestRequests, isCoffeeScriptFile, isCompiledJavascriptFileForMatchingCoffeeScript, isIgnoredCompileFile, isJavascriptFile, isMatchedByAny, isNewer, isRunningTests, options, path, processAllFilesInFolder, processRootFolder, queueFileCompile, queueTest, rootDirPath, runMocha, testRequests, tty, util, waitForCompilationRequests, waitForTestRequests, watchDir, watchFile, watchRootFolder, watchedFiles;

  fs = require('fs');

  path = require('path');

  file = require('file');

  child = require('child_process');

  util = require('util');

  require('colors');

  CoffeeScript = require('coffee-script');

  tty = require('tty');

  module.exports.options = options = {
    excludeDirs: ['.git.*', 'bin.*', 'node_modules.*', 'temp.*'],
    excludeCompileDirs: ['.git.*', 'bin.*', 'test.*', 'node_modules.*', 'temp.*']
  };

  rootDirPath = "";

  filesToCleanup = [];

  watchedFiles = [];

  compilationRequests = [];

  testRequests = [];

  isRunningTests = false;

  module.exports.test = function() {
    return true;
  };

  module.exports.watchDir = function(dirPath) {
    if (!path.existsSync(dirPath)) {
      console.log("Cannot watch '" + dirPath + "'. Directory does not exist.");
      return;
    }
    rootDirPath = dirPath;
    console.log("watching dir: " + rootDirPath);
    waitForCompilationRequests();
    waitForTestRequests();
    watchRootFolder();
    processRootFolder();
    cleanAllCompiledFilesOnProcessExit();
    return queueTest();
  };

  waitForCompilationRequests = function() {
    return setInterval(handleCompileRequests, 50);
  };

  handleCompileRequests = function() {
    var f, requests, _i, _len, _results;
    if (isRunningTests) return;
    if (compilationRequests.length > 0) {
      console.log(("Compiling..." + compilationRequests.length).green);
    }
    requests = compilationRequests;
    compilationRequests = [];
    _results = [];
    for (_i = 0, _len = requests.length; _i < _len; _i++) {
      f = requests[_i];
      _results.push(compileFile(f));
    }
    return _results;
  };

  waitForTestRequests = function() {
    return setInterval(handleTestRequests, 500);
  };

  handleTestRequests = function() {
    if (isRunningTests) return;
    if (testRequests.length > 0) {
      testRequests = [];
      try {
        isRunningTests = true;
        return runMocha(function() {
          return isRunningTests = false;
        });
      } catch (error) {
        return console.log(("ERROR running test: " + error).red);
      }
    }
  };

  watchRootFolder = function() {
    return watchDir(rootDirPath, options.excludeDirs);
  };

  processRootFolder = function() {
    return processAllFilesInFolder(rootDirPath);
  };

  cleanAllCompiledFilesOnProcessExit = function() {
    return process.on('exit', function() {
      var filePath, _i, _len, _results;
      console.log("Cleaning " + filesToCleanup.length + " compiled files.");
      _results = [];
      for (_i = 0, _len = filesToCleanup.length; _i < _len; _i++) {
        filePath = filesToCleanup[_i];
        _results.push(fs.unlinkSync(filePath));
      }
      return _results;
    });
  };

  processAllFilesInFolder = function(dirPath) {
    handleAllFiles(dirPath, options.excludeDirs);
    return compileAllFiles(dirPath, options.excludeCompileDirs);
  };

  enumerateAllFiles = function(rootDirPath, excludeDirs, callbackPerFile) {
    if (!excludeDirs) throw "ERROR MISSING EXCLUDES";
    return file.walkSync(rootDirPath, function(dirPath, dirs, files) {
      var dirName, fullPaths, p;
      dirName = path.relative(rootDirPath, dirPath);
      if (isMatchedByAny(dirName, excludeDirs)) return;
      fullPaths = (function() {
        var _i, _len, _results;
        _results = [];
        for (_i = 0, _len = files.length; _i < _len; _i++) {
          p = files[_i];
          _results.push(path.join(dirPath, p));
        }
        return _results;
      })();
      return fullPaths.forEach(function(filePath) {
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
    return false;
  };

  handleDetectedFile = function(filePath) {
    if (isCompiledJavascriptFileForMatchingCoffeeScript(filePath)) {
      cleanupFile(filePath);
    }
    return watchFile(filePath);
  };

  cleanupFile = function(filePath) {
    if (filesToCleanup.indexOf(filePath) < 0) return filesToCleanup.push(filePath);
  };

  handleAllFiles = function(dirPath, excludeDirs) {
    return enumerateAllFiles(dirPath, excludeDirs, function(dirPath, filePath) {
      return handleDetectedFile(filePath);
    });
  };

  compileAllFiles = function(dirPath, excludeDirs) {
    return enumerateAllFiles(dirPath, excludeDirs, function(dirPath, filePath) {
      if (isCoffeeScriptFile(filePath)) return queueFileCompile(filePath);
    });
  };

  compileFile = function(filePath) {
    if (!isCoffeeScriptFile(filePath)) console.log(("NOT COFFEE:" + filePath).red);
    if (isCoffeeScriptFile(filePath)) return compileToJavascript(filePath);
  };

  queueTest = function() {
    if (testRequests.length === 0) return testRequests.push('test');
  };

  queueFileCompile = function(filePath) {
    if (compilationRequests.indexOf(filePath) < 0) {
      return compilationRequests.push(filePath);
    }
  };

  watchDir = function(dirPath, excludeDirs) {
    return fs.watch(dirPath, function(event, filename) {
      if (isRunningTests) return;
      processAllFilesInFolder(rootDirPath, excludeDirs);
      return queueTest();
    });
  };

  watchFile = function(filePath) {
    if (!path.existsSync(filePath)) return;
    if (watchedFiles.indexOf(filePath) >= 0) return;
    watchedFiles.push(filePath);
    return fs.watch(filePath, function(event, filename) {
      if (isRunningTests) return;
      if (path.existsSync(filePath)) {
        if (!isCompiledJavascriptFileForMatchingCoffeeScript(filePath) && !isIgnoredCompileFile(filePath)) {
          if (isCoffeeScriptFile(filePath)) queueFileCompile(filePath);
        }
      }
      return queueTest();
    });
  };

  isIgnoredCompileFile = function(filePath) {
    var relativePath;
    relativePath = path.relative(rootDirPath, filePath);
    console.log(relativePath);
    console.log(options.excludeCompileDirs);
    return isMatchedByAny(relativePath, options.excludeCompileDirs);
  };

  runMocha = function(cbFinished) {
    var mochaPath, opt, proc;
    if (!path.existsSync('test')) return;
    console.log('Testing...'.green);
    try {
      opt = {
        cwd: process.cwd(),
        setsid: true
      };
      mochaPath = path.join(__dirname, '../node_modules/mocha/bin/_mocha');
      proc = child.spawn(process.argv[0], [mochaPath], opt);
      proc.stdout.pipe(process.stdout);
      proc.stderr.pipe(process.stdout);
      return proc.on('exit', function() {
        console.log();
        console.log("Testing completed.".green);
        return cbFinished();
      });
    } catch (error) {
      console.log("ERROR starting tests >".red);
      console.log(error);
      return cbFinished();
    }
  };

  compileToJavascript = function(filePath) {
    var javascriptFilePath;
    javascriptFilePath = changeToJavascriptExtension(filePath);
    if (path.existsSync(javascriptFilePath)) {
      if (isNewer(javascriptFilePath, filePath)) return;
      console.log("re-compiling " + filePath + " -> " + javascriptFilePath);
    } else {
      console.log("compiling " + filePath + " -> " + javascriptFilePath);
    }
    return compileCoffeeScriptFileToJavascriptFile(filePath, javascriptFilePath);
  };

  compileCoffeeScriptFileToJavascriptFile = function(coffeePath, jsPath) {
    var code, compiledJs;
    try {
      code = fs.readFileSync(coffeePath).toString();
      compiledJs = CoffeeScript.compile(code, getCoffeeScriptOptions(coffeePath));
      fs.writeFileSync(jsPath, compiledJs);
    } catch (error) {
      console.log(("Error compiling " + coffeePath + ":").red + error);
      if (path.existsSync(jsPath)) fs.unlinkSync(jsPath);
    }
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
      bare: false
    };
  };

  isCoffeeScriptFile = function(filePath) {
    return path.extname(filePath) === '.coffee';
  };

  isJavascriptFile = function(filePath) {
    return path.extname(filePath) === '.js';
  };

  isCompiledJavascriptFileForMatchingCoffeeScript = function(filePath) {
    return isJavascriptFile(filePath) && path.existsSync(changeToCoffeeScriptExtension(filePath));
  };

  changeToCoffeeScriptExtension = function(filePath) {
    return changeExtension(filePath, '.coffee');
  };

  changeToJavascriptExtension = function(filePath) {
    return changeExtension(filePath, '.js');
  };

  changeExtension = function(filePath, newExtension) {
    var dirname, nameWithoutExtension, oldExtension;
    dirname = path.dirname(filePath);
    oldExtension = path.extname(filePath);
    nameWithoutExtension = path.basename(filePath, oldExtension);
    return path.join(dirname, nameWithoutExtension + newExtension);
  };

}).call(this);
