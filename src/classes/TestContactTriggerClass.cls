/**
 * This class contains unit tests for validating the behavior of Apex classes
 * and triggers.
 *
 * Unit tests are class methods that verify whether a particular piece
 * of code is working properly. Unit test methods take no arguments,
 * commit no data to the database, and are flagged with the testMethod
 * keyword in the method definition.
 *
 * All test methods in an organization are executed whenever Apex code is deployed
 * to a production organization to confirm correctness, ensure code
 * coverage, and prevent regressions. All Apex classes are
 * required to have at least 75% code coverage in order to be deployed
 * to a production organization. In addition, all triggers must have some code coverage.
 * 
 * The @isTest class annotation indicates this class only contains test
 * methods. Classes defined with the @isTest annotation do not count against
 * the organization size limit for all Apex scripts.
 *
 * See the Apex Language Reference for more information about Testing and Code Coverage.
 */
@isTest
private class TestContactTriggerClass {
	private static final Id contactRecTypeId = [select Id from RecordType where name='Child'].Id;
    static testMethod void testContactTrigger() {
    	npo02__Household__c hh = new npo02__Household__c(name = 'TEst HH');
    	insert hh;
    	
    	System.assertEquals(null, [select Number_of_Children__c from npo02__Household__c where id =:hh.id].Number_of_Children__c);
    	
        //create a batch of Contacts        
        List<Contact> listOfContacts = new List<Contact>();
        for (Integer i=0; i<10 ; i++) {
        	Contact c = new Contact(LastName='Test', RecordTypeID=contactRecTypeId, npo02__Household__c=hh.id);
        	listOfContacts.add(c);
        }
        insert listOfContacts;        
        //now test that the number of children on the household has been updated
        System.assertEquals(10, [select Number_of_Children__c from npo02__Household__c where id =:hh.id].Number_of_Children__c);
        
        //now delete one of the child contacts
        delete listOfContacts.get(0);
        listOfContacts.remove(0);
        System.assertEquals(9, [select Number_of_Children__c from npo02__Household__c where id =:hh.id].Number_of_Children__c);
        
        //create a new household
        npo02__Household__c hh2 = new npo02__Household__c(name = 'TEst HH2');
    	insert hh2;
    	
    	//update - move all remaining contacts to new household
    	for (Contact c: listOfContacts) {
    		c.npo02__Household__c = hh2.id;
    	}
    	update listOfContacts;
    	System.assertEquals(9, [select Number_of_Children__c from npo02__Household__c where id =:hh2.id].Number_of_Children__c);
    }    
}