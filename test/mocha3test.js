(function() {
  var ariel, coverage, runforcover, testFs;

  testFs = require('./testFs');

  runforcover = require('runforcover');

  coverage = runforcover.cover('.*/lib/.*');

  ariel = require('../lib/ariel');

  coverage.release();

  describe('mytest3', function() {
    it('should just work', function() {
      return 2..should.equal(2);
    });
    it('should not work', function() {
      return 3..should.equal(3);
    });
    it('should test ariel', function() {
      return ariel.test().should.be["true"];
    });
    return it('should compile javascript', function() {
      var testDir;
      testDir = testFs.createTestDir();
      testFs.createDummyCoffeeFile(testDir);
      return ariel.watchDir(testDir);
    });
  });

  module.exports = coverage;

}).call(this);
