runforcover = require 'runforcover'

module.exports = coverage = runforcover.cover();
ariel = require '../lib/ariel'
coverage.release()

describe 'mytest3', ->

  it 'should just work', ->
    2.should.equal(2)

  it 'should not work', ->
    3.should.equal(3)

  it 'should test ariel', ->
    ariel.test().should.be.true