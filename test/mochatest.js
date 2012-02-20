(function() {
  var ariel;

  ariel = require('../lib/ariel');

  describe('mytest', function() {
    it('should just work', function() {
      return 2..should.equal(2);
    });
    it('should not work', function() {
      return 3..should.equal(3);
    });
    return it('should test ariel', function() {
      return ariel.test().should.be["true"];
    });
  });

}).call(this);
