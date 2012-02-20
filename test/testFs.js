(function() {
  var createTempRoot, deleteTempRootOnExit, file, fs, hasRegisteredForDeletingTempRoot, path, removeDir, tempRoot, wrench;

  fs = require('fs');

  file = require('file');

  wrench = require('wrench');

  path = require('path');

  tempRoot = path.join(process.cwd(), 'tempTest');

  hasRegisteredForDeletingTempRoot = false;

  module.exports.createTestDir = function() {
    var i, testDirPath;
    createTempRoot();
    i = 0;
    while (true) {
      i++;
      testDirPath = path.join(tempRoot, "test-" + i);
      if (path.existsSync(testDirPath)) continue;
      fs.mkdirSync(testDirPath);
      return testDirPath;
    }
  };

  createTempRoot = function() {
    if (!path.existsSync(tempRoot)) fs.mkdirSync(tempRoot);
    if (!hasRegisteredForDeletingTempRoot) return deleteTempRootOnExit();
  };

  deleteTempRootOnExit = function() {
    process.on('exit', function() {
      return removeDir(tempRoot);
    });
    return hasRegisteredForDeletingTempRoot = true;
  };

  removeDir = function(dirPath) {
    var failSilently;
    console.log('removing dir');
    failSilently = true;
    return wrench.rmdirSyncRecursive(dirPath, failSilently);
  };

  module.exports.createDummyCoffeeFile = function(dirPath) {
    var dummyPath, i;
    if (!path.existsSync(dirPath)) file.mkdirsSync(dirPath);
    i = 0;
    while (true) {
      i++;
      dummyPath = path.join(dirPath, "dummy-" + i + ".coffee");
      if (path.existsSync(dummyPath)) continue;
      fs.writeFileSync(dummyPath, '### DUMMY FILE #' + ("" + i));
      return dummyPath;
    }
  };

}).call(this);
