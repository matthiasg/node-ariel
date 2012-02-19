ariel = require '../lib/ariel'

describe 'mytest', ->

  it 'should just work', ->
    2.should.equal(2)

  it 'should not work', ->
    3.should.equal(3)

  it 'should test ariel', ->
    ariel.test().should.be.true