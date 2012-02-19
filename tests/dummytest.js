var test = require("tap").test;

thingie = "thing"

test("make sure the thingie is a thing", function (t) {
  t.equal(thingie, "thing", "thingie should be thing")
  t.type(thingie, "string", "type of thingie is string")
  t.ok(true, "this is always true")
  t.notOk(false, "this is never true")

  t.end()
})