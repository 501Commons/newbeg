public without sharing class ContactTriggerClass {
	public static void MainEntry (List<Contact> newList, Map<Id, Contact> newMap,
                            			List<Contact> oldList, Map<Id, Contact> oldMap){
          if (trigger.isAfter) {//After
                if (trigger.isInsert) {                	
                    updateRelatedObjects(newMap);                                   
                } else if (trigger.isDelete) {
                    updateRelatedObjects(oldMap);
                } else if (trigger.isUpdate) {                    
                    updateRelatedObjects(oldMap, newMap);
                }
          } 	                 				
    }
    
    private static void updateRelatedObjects(Map<Id, Contact> newMap) {
    	//for all contacts inserted check their record type and get their household
    	Set<Id> householdSet = new Set<Id>();
    	for (Contact c : newMap.values()) {
    		if ((c.Role_in_Household__c == 'Child' || c.Record_Type_Name__c == 'Child') 
    				&& c.npo02__Household__c <> null) {
    			householdSet.add(c.npo02__Household__c);
    		}
    	}
    	updateHouseholds(householdSet);
    }
    
    private static void updateRelatedObjects(Map<Id, Contact> oldMap, Map<Id, Contact> newMap) {
    	//for all contacts updated check their record type and get their household
    	Set<Id> householdSet = new Set<Id>();
    	for (Contact newC : newMap.values()) {
    		Contact oldC = oldMap.get(newC.id);
    		if (newC.Role_in_Household__c <> oldC.Role_in_Household__c ||
    				newC.RecordTypeId <> oldC.RecordTypeId || 
    				newC.npo02__Household__c <> oldC.npo02__Household__c) {
    					if ((newC.Role_in_Household__c == 'Child' || newC.Record_Type_Name__c == 'Child') 
    							&& newC.npo02__Household__c <> null) {
    						householdSet.add(newC.npo02__Household__c);
    					}
    		}
    	}
    	updateHouseholds(householdSet);
    }
    
    /*
    * Update households with the number of children
    */
    private static void updateHouseholds(Set<Id> households) {
    	Map<Id, npo02__Household__c> householdsToUpdate = new Map<Id, npo02__Household__c> 
    														([select id, Number_of_Children__c from npo02__Household__c 
    															where id in :households]);    	
    	AggregateResult[] children = [select npo02__Household__c, count(id) 
    								from Contact where (Record_Type_Name__c='Child' or Role_in_Household__c = 'Child') 
    								and npo02__Household__c in :households group by npo02__Household__c];
		for (AggregateResult ar : children)  {	
		   Id hhId = (Id)ar.get('npo02__Household__c');	
		   npo02__Household__c hh = householdsToUpdate.get(hhId); 				    
		   hh.Number_of_Children__c = (Integer)ar.get('expr0');
		}  
		update householdsToUpdate.values(); 								
    }
}