/** 
* Written by Nineta Martinov and Patrick Tewson, copyright (c) 2013 501Commons
* Utility class to perform various functionaliy on Service Participation operations.
*/
public without sharing class ServiceParticipationTriggerClass {
	  	
	public static void MainEntry (List<ServiceParticipation__c> newList, Map<Id, ServiceParticipation__c> newMap,
                            			List<ServiceParticipation__c> oldList, Map<Id, ServiceParticipation__c> oldMap){
                  
         if (trigger.isAfter) {//after
            if (trigger.isInsert) {                	
               //attach contracts
               attachContracts(newMap);                                                       
            } 
         } else { //Before          	
          	if (trigger.isDelete) {          		
          		deleteContractParticipations(oldList);
          	}
         }                     		          	
    }
    
    /*
    * Delete the contract participations for the service participaions being deleted
    */
    private static void deleteContractParticipations(List<ServiceParticipation__c> oldList) {    	
    	//get all contract participations for all service participations being deleted
    	List<ContractParticipation__c> cPartList = [select id, Service_Participation__c, Contract__c 
    													from ContractParticipation__c 
    													where Service_Participation__c in :oldList];		   												
    	delete cPartList;	
    	deleteOutcomesWithNoMilestone(oldList, cPartList);											
    }
    
    /*
    * Some outcomes might not have milestones at all so we'll have to locate the via the 
    * case record and delete them. Traverse from Service Participation -> Case Record
    * and look for Outcomes that should be deleted
    */
    private static void deleteOutcomesWithNoMilestone(List<ServiceParticipation__c> oldList, 
    														List<ContractParticipation__c> cpList) {
    	//for each Service Participation get the case record
    	Map<Id, Id> spToCaseRecordsMap = new Map<Id, Id>();
    	//map of service participation with contracts
    	Map<Id, Set<Id>> spWithContracts = new Map<Id, Set<Id>>(); 
    	
    	for (ServiceParticipation__c sp : oldList) {
    		spToCaseRecordsMap.put(sp.id, sp.Case_Record__c);
    		for (ContractParticipation__c cp : cpList) {
    			if (sp.id  == cp.Service_Participation__c) {
    				if (spWithContracts.get(sp.id) == null)
    					spWithContracts.put(sp.id, new Set<Id>());
    				spWithContracts.get(sp.id).add(cp.Contract__c);		
    			}
    		}
    	}
    	//for each Case Record get the Outcomes that have no milestones
    	List<Outcome__c> outcomesToDelete = new List<Outcome__c>();
    	for (Outcome__c oc : [select id, Total_Number_of_Milestones__c, Parent_Case_Record__c, Contract__c 
    							from Outcome__c 
    							where Parent_Case_Record__c in :spToCaseRecordsMap.values()
    							and Total_Number_of_Milestones__c = 0]){
    		//check if the contract on the service participation matches the one on the outcome
    		//then we can safely assume that the outcome was created by the service participation
    		for (Id spId : spToCaseRecordsMap.keySet()) {
    			if (spToCaseRecordsMap.get(spId) == oc.Parent_Case_Record__c) {
    				//if ther case record matches then this is the service participation
    				if (spWithContracts.get(spId).contains(oc.Contract__c)) {
    					//put in list to delete
    					outcomesToDelete.add(oc);
    				}
    			}	
    		}
    		    		    											
   		}
		delete outcomesToDelete;    										
    }
    
    /*
    * For each ServiceParticipation, get all Program Distributions, get all Contracts (Renewed and Locked)
    * and insert Contract Participations.
    */
    private static void attachContracts(Map<Id, ServiceParticipation__c> newMap) {
    	List<Id> progs = new List<Id>();
    	List<Id> spList = new List<Id>(); //list of serv part needing contract participations
    	for (ServiceParticipation__c sp : newMap.values()) {
    		if (sp.Program__c != null) {
    			progs.add(sp.Program__c);
    			spList.add(sp.Id);
    		}
    	}    	
    	if (progs.size() > 0) {
    		List<ContractParticipation__c> cpList = new List<ContractParticipation__c>();
	    	for (Contract_Program_Distribution__c cpd : [select id, Program__c, Contract__c, 
	    													Contract__r.IsLocked__c, Contract__r.Status__c 
	    													from Contract_Program_Distribution__c    													
	    													where Program__c in :progs and 
	    													(Contract__r.Status__c = 'Renewed' or Contract__r.Status__c = 'New') and
	    													Contract__r.IsLocked__c = true]){
				for (Id spId : spList) {	    														
	    			ContractParticipation__c cp = new ContractParticipation__c(Service_Participation__c=spId,
	    												Contract__c=cpd.Contract__c);
	    			cpList.add(cp);									
				}												
	    	}	    	
	    	insert cpList;	    	
    	}    	    
    }
    
}