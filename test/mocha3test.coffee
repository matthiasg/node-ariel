testFs = require './testFs'

runforcover = require 'runforcover'

coverage = runforcover.cover '.*/lib/.*'
ariel = require '../lib/ariel'
coverage.release()

describe 'mytest3', ->

  it 'should just work', ->
    2.should.equal(2)

  it 'should not work', ->
    3.should.equal(4)

  it 'should test ariel', ->
    ariel.test().should.be.true

  it 'should compile javascript', ->
    testDir = testFs.createTestDir()
    testFs.createDummyCoffeeFile testDir    


module.exports = coverage