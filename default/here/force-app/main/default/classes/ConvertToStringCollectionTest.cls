@isTest
public with sharing class ConvertToStringCollectionTest{
    
    @isTest
    public static void canConvertString(){
        //String testString = 'foo,bar,baz';
        ConvertToStringCollection.Request testReq = new ConvertToStringCollection.Request();
        testReq.initialString = 'foo,bar,baz';
        testReq.delimiter = ',';

        List<ConvertToStringCollection.Request> testReqList = new List<ConvertToStringCollection.Request>();
        testReqList.add(testReq);

        List<ConvertToStringCollection.Response> testResponseList = ConvertToStringCollection.execute(testReqList);
     
        System.assertEquals(testResponseList[0].stringCollection[0], 'foo');
    }
}