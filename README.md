# foxmock
Mocking framework for Microsoft Visual FoxPro

foxmock is best used together with unit test tools like foxUnit. With foxmock you can define objects in your test code using a fluent interface without having to define test specific classes in a separate place. To use foxmock, add the following line to your SetUp method:
```
	Public mock
	mock = NewObject("foxMock", "foxMock.prg")
```
Adjust the path to foxMock as necessary. In your TearDown method put
```
	Release mock
```
Within your test you can then create objects with properties and method like this:
```
	Local loObj
	loObj = mock.New ;
		.Property("lDebugMode").Is(".T.") ;
		.CallTo("IsAdmin").Return(".F.")
	This.AssertTrue (loObj.lDebugMode)
	This.AssertFalse (loObj.IsAdmin ("user"))
```
There are many more options available. Please refer to the test cases until a better documentation is available.
