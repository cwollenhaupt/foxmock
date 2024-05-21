*========================================================================================
* FoxMock unit tests
*========================================================================================
Define Class Test_foxMock as FxuTestCase OF FxuTestCase.prg

	#IF .F.
		LOCAL THIS AS Test_foxMock OF Test_foxMock.PRG
	#ENDIF
	
*========================================================================================
Procedure Setup
	Public mock
	mock = NewObject("foxMock", "tools\foxMock.prg")

*========================================================================================
Procedure TearDown
	mock.CleanUp ()
	Release mock

*========================================================================================
Procedure Test_Mock_Basic_Property
	Local loObj
	loObj = mock.New ;
		.Property("lDebugMode").Is(".T.")
	This.AssertTrue (loObj.lDebugMode)

*========================================================================================
Procedure Test_Mock_Basic_Method
	Local loObj
	loObj = mock.New ;
		.CallTo("IsAdmin").Return(".F.")
	This.AssertFalse (loObj.IsAdmin ("user"))

*========================================================================================
Procedure Test_Mock_ReturnObject
	Local loObj, loTest
	loObj = mock.New ;
		.CallTo("Test").ReturnObject( ;
			mock.New ;
				.Property("cTest").Is("'xx'") ;
				.AsObject ;
		)
	loTest = loObj.Test ()
	This.AssertEquals ("xx", loTest.cTest)

*========================================================================================
Procedure Test_Mock_AsObject_Named
	Local loObj
	loObj = mock.New ;
		.Property("cTest").Is("'xx'") ;
		.AsObject("test")
	This.AssertEquals ("xx", mock["test"].cTest)

*========================================================================================
Procedure Test_Mock_ChangeProperty
	Local loObj
	loObj = mock.New ;
		.Property("cTest").Is("'xx'")
	loObj.cTest = "yy"
	This.AssertEquals ("yy", loObj.cTest)

*========================================================================================
Procedure Test_Mock_ExpectCalled
	Local loObj
	loObj = mock.New ;
		.Expect.CallTo("Test")
	loObj.Test()
	mock.VerifyAllExpectations()
		
*========================================================================================
Procedure Test_Mock_ExpectNotCalled
	Local loObj, loEx as Exception
	loObj = mock.New ;
		.Expect.CallTo("Test")
	Try
		mock.VerifyAllExpectations()
		This.AssertTrue(.F., "VerifyAllExpectations should not pass")
	Catch to loEx
		This.AssertEquals("Expectation failed for test", loEx.Message)
	EndTry 
		
*========================================================================================
Procedure Test_Mock_NestedObjects

	* Define a service broker with one service
	Local loServiceBroker
	loServiceBroker = mock.New ;
		.CallTo("RequestService").ReturnObject( ;
			mock.New ;
				.Method("GetReference").Return("NULL") ;
				.Expect.CallTo("SetReference") ;
			.AsObject ;
		) ;
		.Property("oProxy").Is(".NULL.") 

	* This code would normally be the tested one
	Local loService, loReference
	If not IsNull(loServiceBroker.oProxy)
		loServiceBroker = loServiceBroker.oProxy
	EndIf
	loService = loServiceBroker.RequestService("ReferenceHandling")
	loReference = loService.GetReference("menu")
	If IsNull(m.loReference)
		loReference = CreateObject("Empty")
		AddProperty(loReference,"lProperty", .T.)
		loService.SetReference("menu", m.loReference)
	EndIf
	loReference.lProperty = .F.
	
	* Make sure we actually called SetReference in the code above
	mock.VerifyAllExpectations()

*========================================================================================
Procedure Test_Mock_FoundationClass
	Local loObj
	loObj = mock.New("FoundationTestClass") ;
		.CallTo("GetValue").Returns("'result'")
	This.AssertEquals("RESULT", loObj.ToUpper())

*========================================================================================
Procedure Test_ExpectCallToWhen
	Local loDialogs
	loDialogs = mock.new.expect.CallTo("Alert").When("'X'")
	loDialogs.Alert("X")
	mock.VerifyAllExpectations()
	
*========================================================================================
Procedure Test_ExpectCallToFirst
	Local loDialogs
	loDialogs = mock.new ;
		.expect.CallTo("Alert").When("'X'") ;
		.CallTo("Alert").When("'Y'")
	loDialogs.Alert("Y")
	Try
		mock.VerifyAllExpectations()
		This.AssertTrue(.F., "VerifyAllExpectations should not pass")
	Catch to loEx
		This.AssertEquals("Expectation failed for alert", loEx.Message)
	EndTry 

*========================================================================================
Procedure Test_ExpectCallToSecond
	Local loDialogs
	loDialogs = mock.new ;
		.CallTo("Alert").When("'X'") ;
		.expect.CallTo("Alert").When("'Y'")
	loDialogs.Alert("Y")
	mock.VerifyAllExpectations()

*========================================================================================
Procedure Test_TextMerge
	Local loData, lcText
	loData = mock.new.Property("Data").Is("'OK'")
	lcText = Textmerge("Result: <<loData.Data>>")
	This.AssertEquals ("Result: OK", m.lcText)
	
*========================================================================================
Procedure Test_Scatter
	Create Cursor TestData (cField C(12), Data V(10))
	Insert into TestData Values ("test passed", "not OK")
	Local loData, lcText
	loData = mock.new;
		.Property("Data").Is("'OK'") ;
		.Scatter("'TestData', 'RECORD 1'")
	This.AssertEquals ("test passed ", loData.cField)
	This.AssertEquals ("OK", loData.Data)

*========================================================================================
Procedure Test_Mock_IsObject
	Local loRef
	loRef = mock.new ;
		.Property ("oChild").IsObject ( ;
			mock.new.Property ("nValue").Is ("1").AsObject ;
		)
	This.AssertEquals (1, loRef.oChild.nValue)

*========================================================================================
Procedure Test_ThenReturn
	Local loRef
	loRef = mock.new ;
		.Method("Test").Return("1").Then.Return("2")
	This.AssertEquals (1, loRef.Test ())
	This.AssertEquals (2, loRef.Test ())
	This.AssertEquals (.T., loRef.Test ())

*========================================================================================
Procedure Test_WhenThenReturn
	Local loRef
	loRef = mock.new ;
		.Method("Test");
			.Return("3") ;
			.When(".T.").Return("1").Then.Return("2")
	This.AssertEquals (1, loRef.Test (.T.))
	This.AssertEquals (3, loRef.Test ())
	This.AssertEquals (2, loRef.Test (.T.))
	
*========================================================================================
Procedure Test_ThenReturnReturn
	Local loRef
	loRef = mock.new ;
		.Method("Test").Return("1").Then.Return("2").Return("3")
	This.AssertEquals (1, loRef.Test ())
	This.AssertEquals (2, loRef.Test ())
	This.AssertEquals (3, loRef.Test ())

*========================================================================================
Procedure Test_IgnoreMultipleThen
	Local loRef
	loRef = mock.new ;
		.Method("Test").Return("1").Then.Return("2").Then.Return("3")
	This.AssertEquals (1, loRef.Test ())
	This.AssertEquals (2, loRef.Test ())
	This.AssertEquals (3, loRef.Test ())
	
*========================================================================================
Procedure Test_CleanUp
	Local loRef, lnFiles, laFiles[1], lnFilesAfter
	lnFiles = ADir (laFiles, Addbs (GetEnv ("TEMP"))+"_*.fxp")
	loRef = mock.new.Method("Test").Returns (".T.")
	=loRef.Test ()
	=loRef.Test ()
	loRef = null
	mock.CleanUp ()
	lnFilesAfter = ADir (laFiles, Addbs (GetEnv ("TEMP"))+"_*.fxp")
	This.AssertEquals (m.lnFiles, m.lnFilesAfter)

*========================================================================================
Procedure Test_Bindable
	Local loRef, loHandler
	loHandler = mock.new ;
		.Property ("nValue").Is ("42") ;
		.expect.CallTo ("OnEvent") ;
		.Bindable
	BindEvent (_Screen, "Paint", m.loHandler, "OnEvent")
	_Screen.Paint ()
	UnBindEvents (_Screen, "Paint", m.loHandler, "OnEvent")
	mock.VerifyAllExpectations ()
	This.AssertEquals (42, m.loHandler.nValue)
	
*========================================================================================
Procedure Test_Reference
	Local loRef, loStatus
	loRef = mock.new ;
		.Method("Send") ;
			.Returns(".T.") ;
			.Reference("2").IsObject( ;
				mock.new.Property("HttpStatus").Is("200").AsObject ;
			)
	loRef.Send ("data", @loStatus)
	This.AssertEquals (200, m.loStatus.HttpStatus)
	
*========================================================================================
Procedure Test_Reference_Value
	Local loRef, lnStatus
	loRef = mock.new ;
		.Method("Send") ;
			.ReturnsObject(mock.new.AsObject) ;
			.Reference("2").Is("404")
	loRef.Send ("data", @lnStatus)
	This.AssertEquals (404, m.lnStatus)
	
*========================================================================================
Procedure Test_Reference_Fail
	Local loRef, loStatus
	loRef = mock.new ;
		.Method("Send") ;
			.When ("'ok', .F.") ;
				.Returns(".T.") ;
				.Reference("2").IsObject( ;
					mock.new.Property("HttpStatus").Is("200").AsObject ;
				) ;
			.When ("'fail', .F.") ;
				.Returns(".T.") ;
				.Reference("2").IsObject( ;
					mock.new.Property("HttpStatus").Is("500").AsObject ;
				)
	loRef.Send ("ok", @loStatus)
	This.AssertEquals (200, m.loStatus.HttpStatus)
	loRef.Send ("fail", @loStatus)
	This.AssertEquals (500, m.loStatus.HttpStatus)
	
EndDefine 

*========================================================================================
* This class is used in the Mock_FoundationClass test.
*========================================================================================
Define Class FoundationTestClass as Custom
Procedure ToUpper
Return Upper(This.GetValue())
Procedure GetValue
Return ""
EndDefine 