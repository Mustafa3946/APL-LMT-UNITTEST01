
local luaunit = require('src.luaunit')

TestAdd = {}
function TestAdd:testAddPositive()
    luaunit.assertEquals(add(1,1),2)
end

function TestAdd:testAddZero()
    luaunit.assertEquals(add(1,0),0)
    luaunit.assertEquals(add(0,5),0)
    luaunit.assertEquals(add(0,0),0)
end

function TestAdd:testAddError()
    luaunit.assertErrorMsgContains('Can only add positive or null numbers, received 2 and -3', add, 2, -3)
end

function TestAdd:testAdder()
    f = adder(3)
    luaunit.assertIsFunction( f )
    luaunit.assertEquals( f(2), 5 )
end
-- end of table TestAdd

function testAdder()
    f = adder(3)
    luaunit.assertIsFunction( f )
    luaunit.assertEquals( f(2), 5 )
end

TestDiv = {}
function TestDiv:testDivPositive()
    luaunit.assertEquals(div(4,2),2)
end

function TestDiv:testDivZero()
    luaunit.assertEquals(div(4,0),0)
    luaunit.assertEquals(div(0,5),0)
    luaunit.assertEquals(div(0,0),0)
end

function TestDiv:testDivError()
    luaunit.assertErrorMsgContains('Can only divide positive or null numbers, received 2 and -3', div, 2, -3)
end
-- end of table TestDiv


luaunit.LuaUnit.verbosity = 2
local runner = luaunit.LuaUnit.new()
runner:setOutputType("tap")
--os.exit( luaunit.LuaUnit.run() )
os.exit( runner:runSuite() )

