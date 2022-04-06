/*******************************************************************************************
* @author           Demandblue
* @version          1.0 
* @Status           Development Completed
* @description      This helper is used to update the lastmodified datetime in opportunity track object and called from ContentVersionTrigger 
*********************************************************************************************
Version    	Date        	Team    	Comments
*********************************************************************************************
* 1    	22 May 2020   	 	Siva    	Initial Development 
*********************************************************************************************/

public class ContentVersionHelper {
    
    public static void updateOpportunityTrack(List<ContentVersion>  contentVersionList){
        try{
            Set<Id> contentDocumentIds = new Set<Id>();
            
            
            
            //get the contentdocument Id
            for(ContentVersion contentVersionObject :contentVersionList)
            {
                if(contentVersionObject.ContentDocumentId != null)
                {
                    contentDocumentIds.add(contentVersionObject.ContentDocumentId); //get the contentdocument Id and add to set of contentDocumentIdSet
                }
            }
            
            //get the ContentDocumentLink record related to contentDocument.
            List<ContentDocumentLink> contentDocumentList = [SELECT ContentDocumentId, LinkedEntityId FROM ContentDocumentLink WHERE ContentDocumentId IN:contentDocumentIds ];
			updateOpportunityTrackSub(contentDocumentList);
            
            
        }
        catch(Exception Error){
            system.debug('UpdateContentVersionDocument.error'+Error);
        }
    }
	public static void updateOpportunityTrackSub(List<ContentDocumentLink> contentDocumentList){
	try{
		Set<Id> opportunityIds = new Set<Id>();
		Map<Id,Id> contentVersionAndOpportunityIdMap = new Map<Id,Id>();
		//get the only the opportunity related ContentDocumentLink and add the opportunity Id to List
		for(ContentDocumentLink contentDocumentLinkObject:contentDocumentList) {
			
			String sObjName = contentDocumentLinkObject.LinkedEntityId.getSObjectType().getDescribe().getName(); //Get the sobject type from content document linked Id.
			
			if(sObjName == 'Opportunity') //if the sobject type is opportunity.
			{ 
				opportunityIds.add(contentDocumentLinkObject.LinkedEntityId);
				contentVersionAndOpportunityIdMap.put(contentDocumentLinkObject.LinkedEntityId,contentDocumentLinkObject.ContentDocumentId);
			}
		}
		//get the only the opportunity related ContentDocumentLink and add the opportunity Id to List
		for(ContentDocumentLink contentDocumentLinkObject:contentDocumentList) {
			
			String sObjName = contentDocumentLinkObject.LinkedEntityId.getSObjectType().getDescribe().getName(); //Get the sobject type from content document linked Id.
			
			if(sObjName == 'Opportunity') //if the sobject type is opportunity.
			{ 
				opportunityIds.add(contentDocumentLinkObject.LinkedEntityId);
				contentVersionAndOpportunityIdMap.put(contentDocumentLinkObject.LinkedEntityId,contentDocumentLinkObject.ContentDocumentId);
			}
		}
		if(opportunityIds.size() >0 )
		{
			updateOpportunityTrackSubSub(opportunityIds,contentVersionAndOpportunityIdMap);
		}
	}
	catch(Exception Error){
		system.debug('UpdateContentVersionDocument.error'+Error);
	}
 }
 
  public static void updateOpportunityTrackSubSub(Set<Id> opportunityIds,Map<Id,Id> contentVersionAndOpportunityIdMap){
try{
	Map<Id,Id> opportunityAndOpportunityTrackIdMap = new Map<Id,Id>();
	List<Opportunity_Track__c> opportunityTrackUpsertList = new List<Opportunity_Track__c>();
	for(Opportunity_Track__c opportunityTrackObject : [Select Id, Opportunity__c FROM Opportunity_Track__c WHERE Opportunity__c =: opportunityIds])
	{
		opportunityAndOpportunityTrackIdMap.put(opportunityTrackObject.Opportunity__c,opportunityTrackObject.Id);  // Check Opportunity track contains the opportunity record.
	}
	
	for(Id opportunityid : opportunityIds)
	{
		Opportunity_Track__c opportunityTrackObject = new Opportunity_Track__c();
		if(opportunityAndOpportunityTrackIdMap.containsKey(opportunityid)) // If opporunity track contains the opportunity then update the record
		{
			opportunityTrackObject.Id = opportunityAndOpportunityTrackIdMap.get(opportunityid);
			opportunityTrackObject.LastModified_Date__c = system.now();
			opportunityTrackObject.LastModified_RecordId__c = contentVersionAndOpportunityIdMap.get(opportunityid);
			opportunityTrackUpsertList.add(opportunityTrackObject);
		}
		else // else create opporunity track and update the record.
		{
			opportunityTrackObject.LastModified_Date__c = system.now();
			opportunityTrackObject.Opportunity__c = opportunityid;
			opportunityTrackObject.LastModified_RecordId__c = contentVersionAndOpportunityIdMap.get(opportunityid);
			opportunityTrackUpsertList.add(opportunityTrackObject);
		}
	}
	if(!opportunityTrackUpsertList.isEmpty())
	{
		upsert opportunityTrackUpsertList; // Upsert the opportunity Track record.
	}
}
catch(Exception Error){
	system.debug('UpdateContentVersionDocument.error'+Error);
}
}
	
    
}