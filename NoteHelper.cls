/*******************************************************************************************
* @author           Demandblue
* @version          1.0 
* @Status           Development Completed
* @description      This Class is used to update the LastModifed dateTime on opportunity track object. 
*********************************************************************************************
Version    	Date        	Team    	Comments
*********************************************************************************************
* 1    	22 May 2020    		Siva    	Initial Development 
*********************************************************************************************/
public class NoteHelper {
    
    //Method to refered in Notestrigger to update the opportunity lastmodified date and time
    public static void UpdateNote(List<Note> noteList){
        try{ 
            Set<Id> opportunityIds = New Set<Id>(); 
            Map<Id,Id> oppAndNoteIdMap = new Map<Id,Id>();  
            Map<Id,Id> checkOpportunityMap = new Map<Id,Id>();
            List<Opportunity_Track__c>  opportunityTrackUpsertList = new List<Opportunity_Track__c>();
            
            //get the NoteId from trigger and loop to get ParentId 
            for(Note noteObject:noteList){
                String sobjectType = noteObject.ParentId.getSobjectType().getDescribe().getName(); //Get Opportunity object
                if(sobjectType == 'Opportunity'){
                    oppAndNoteIdMap.put(noteObject.ParentId,noteObject.Id); // add the parentId and Noteobject Id to Map
                    opportunityIds.add(noteObject.ParentId); //add the opportunity Id Set
                }
            }
        }
            catch(Exception Error){
            
            system.debug('Error ---> '+Error.getMessage());
            
        }
        }
        public static void OpportunityTrack(Set<Id> opportunityIds,Map<Id,Id> oppAndNoteIdMap){
            try{
            Map<Id,Id> checkOpportunityMap = new Map<Id,Id>();
            List<Opportunity_Track__c>  opportunityTrackUpsertList = new List<Opportunity_Track__c>();
            if(opportunityIds.size() > 0){
                //Query and get the opportunity track record related to opportunity in above Opportunity List
                Map<Id,Opportunity_Track__c> getOpportunityTrackMap = new Map<Id,Opportunity_Track__c>([Select Id, Opportunity__c,LastModified_Date__c From Opportunity_Track__c where Opportunity__c =:opportunityIds]);
                for(Opportunity_Track__c OpportunityTrackObject : getOpportunityTrackMap.values())
                {
                    checkOpportunityMap.put(OpportunityTrackObject.Opportunity__c,OpportunityTrackObject.Id); // Check Opportunity track contains the opportunity record.
                }
                
                for(Id opportunityid : opportunityIds) 
                {
                    Opportunity_Track__c opportunityTrackObject = new Opportunity_Track__c();
                    if(checkOpportunityMap.containsKey(opportunityid)) // If opporunity track contains the opportunity then update the record 
                    {
                        opportunityTrackObject.Id = checkOpportunityMap.get(opportunityid);
                        opportunityTrackObject.LastModified_Date__c = system.now();
                        opportunityTrackObject.LastModified_RecordId__c = oppAndNoteIdMap.get(opportunityid);
                        opportunityTrackUpsertList.add(opportunityTrackObject);
                    }
                    else // else create opporunity track and update the record.
                    {
                      
                        opportunityTrackObject.LastModified_Date__c = system.now();
                        opportunityTrackObject.Opportunity__c = opportunityid;
                        opportunityTrackObject.LastModified_RecordId__c = oppAndNoteIdMap.get(opportunityid);
                        opportunityTrackUpsertList.add(opportunityTrackObject);
                    }
                }
                
            }
            if(!opportunityTrackUpsertList.isEmpty())
            {
                upsert opportunityTrackUpsertList; // Upsert the opportunity Track record.
            }
            
        }
        
        catch(Exception Error){
            
            system.debug('Error ---> '+Error.getMessage());
            
        }
    }
    
}