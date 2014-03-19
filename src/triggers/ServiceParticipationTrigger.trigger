/** 
* Written by Patrick Tewson, copyright (c) 2013 501Commons
* Trigger to manage Service Participation behavior. Further functionality is documented in the helper class.
*/
trigger ServiceParticipationTrigger on ServiceParticipation__c (before delete, after delete, after insert, after update) {
	ServiceParticipationTriggerClass.MainEntry(trigger.new, trigger.newMap, trigger.old, trigger.oldMap);	
}