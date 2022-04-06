/*******************************************************************************************
* @author           Demandblue
* @version          1.0 
* @Status           Development Completed
* @description      This class is used to validate Opportunity. 
*********************************************************************************************
Version    	Date        	Team    	Comments
*********************************************************************************************
* 1    		20 Mar 2021    	Vignesh    	Initial Development 
*********************************************************************************************/
/*******************************************************************************************
* @author           Demandblue
* @version          1.0 
* @Status           Development Completed
* @description      This class is used to validate Opportunity. 
*********************************************************************************************
Version    	Date        	Team    	Comments
*********************************************************************************************
* 1    		20 Mar 2021    	Vignesh    	Initial Development 
*********************************************************************************************/
public without sharing class OpportunityInventoryUpdation {
    
    
    public static void opportunityInventoryUpdationCreation(Map<Id,Opportunity> oldOpportunityMap, Map<Id,Opportunity> newOpportunityMap)
    {
        
        Set<Id> opportunityWonIds = new Set<Id>();
        Set<Id> opportunityNonWonIds = new Set<Id>();
        
        for(Opportunity opportunityObject : newOpportunityMap.values())
        {
            //When status=Closed Won
            if(opportunityObject.StageName == 'Closed Won' && opportunityObject.StageName != oldOpportunityMap.get(opportunityObject.Id).StageName)
            {
                opportunityWonIds.add(opportunityObject.Id);
            }
            
            //When status=Closed Lost
            if(opportunityObject.StageName == 'Closed Lost' && opportunityObject.StageName != oldOpportunityMap.get(opportunityObject.Id).StageName)
            {
                opportunityNonWonIds.add(opportunityObject.Id);
            }
        }
		
        
        
        opportunityInventoryUpdationCreationMethod(opportunityWonIds,opportunityNonWonIds);
        
        
    }
	
	public static void opportunityInventoryUpdationCreationMethod(Set<Id> opportunityWonIds, Set<Id> opportunityNonWonIds)
	{
		Set<Id> quoteIds = new Set<Id>();
        
        for(SBQQ__Quote__c quoteRecord : [SELECT Id, SBQQ__Opportunity2__c, SBQQ__Primary__c FROM SBQQ__Quote__c where (SBQQ__Opportunity2__c =: opportunityWonIds OR SBQQ__Opportunity2__c =: opportunityNonWonIds) AND SBQQ__Primary__c = true ])
        {
            quoteIds.add(quoteRecord.Id);
        }
        
        List<Inventory_Reserve__c> inventoryList = new List<Inventory_Reserve__c>([SELECT Id,Quote__c,Opportunity__c,Status__c FROM Inventory_Reserve__c WHERE (Opportunity__c IN: opportunityWonIds OR Opportunity__c IN: opportunityNonWonIds) AND Quote__c=:quoteIds AND Status__c = 'Soft Reserved']);
        
        for(Inventory_Reserve__c inventoryReserveObject : inventoryList)
        {
            if(opportunityWonIds.contains(inventoryReserveObject.Opportunity__c))
            {
                //When closed won inventory reserve status changes to Hard Reserved
                inventoryReserveObject.Status__c = 'Hard Reserved';
            }
            if(opportunityNonWonIds.contains(inventoryReserveObject.Opportunity__c))
            {
                //When closed won inventory reserve status changes to Obsolete
                inventoryReserveObject.Status__c = 'Obsolete';
            }
        }
        
        if(!inventoryList.isEmpty())
        {
            update inventoryList;
        }
	}
	
    
    public static void closedWonValidation(List<Opportunity> opportunityRecords)
    {
        Id recTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Hops').getRecordTypeId();
        
        Set<Id> opportunityClosedWonHopsIds = new Set<Id>();
        
        
        for(Opportunity opportunityObject : opportunityRecords)
        {
            if(opportunityObject.RecordTypeId == recTypeId && opportunityObject.StageName == 'Closed Won' && opportunityObject.Product_Line__c=='Hops- Contracted' )
            {
                opportunityClosedWonHopsIds.add(opportunityObject.Id);
            }
        }
        
       closedWonValidationSub(opportunityRecords,opportunityClosedWonHopsIds);
        
    }
	public static void closedWonValidationSub(List<Opportunity> opportunityRecords,Set<Id> opportunityClosedWonHopsIds)
	{
		Set<Id> opportunityDocusignCompletedIds = new Set<Id>();
         Set<Id> opportunityExpiredIds = new Set<Id>();
		 if(!opportunityClosedWonHopsIds.isEmpty())
        {
            
            Set<Id> quoteIds = new Set<Id>();
            
            for(SBQQ__Quote__c quoteRecord : [SELECT Id, SBQQ__Opportunity2__c, SBQQ__Primary__c FROM SBQQ__Quote__c where SBQQ__Opportunity2__c =: opportunityClosedWonHopsIds AND SBQQ__Primary__c = true ])
            {
                quoteIds.add(quoteRecord.Id);
            }
            
            for(Inventory_Reserve__c inventoryObject : [SELECT Id,Quote__c,Opportunity__c,Status__c FROM Inventory_Reserve__c WHERE Opportunity__c IN: opportunityClosedWonHopsIds AND Quote__c=:quoteIds AND (Status__c = 'Expired' OR Status__c = 'Obsolete')])
            {
                opportunityExpiredIds.add(inventoryObject.Opportunity__c); 
            }
            
            List<dsfs__DocuSign_Status__c> docusignStatusList = [SELECT Id, dsfs__Company__c, dsfs__Envelope_Status__c, dsfs__Opportunity__c FROM dsfs__DocuSign_Status__c where dsfs__Envelope_Status__c = 'Completed' AND dsfs__Opportunity__c  IN:opportunityClosedWonHopsIds  ];
            system.debug('docusignStatusList'+docusignStatusList);
            if(!docusignStatusList.isEmpty())
            {
                for(dsfs__DocuSign_Status__c docusignStatusObject : docusignStatusList)
                {
                    opportunityDocusignCompletedIds.add(docusignStatusObject.dsfs__Opportunity__c);
                }
            }
            
        }
        
        closedWonValidationSubSub(opportunityRecords,opportunityExpiredIds,opportunityClosedWonHopsIds,opportunityDocusignCompletedIds);
        
       
         
        
      
      
        
        
	}
	public static void closedWonValidationSubSub(List<Opportunity> opportunityRecords,Set<Id> opportunityExpiredIds,Set<Id> opportunityClosedWonHopsIds,Set<Id> opportunityDocusignCompletedIds)
	{
		Profile p = [Select Name from Profile where Id =: userinfo.getProfileid()];
        
        for(Opportunity opportunityObject : opportunityRecords)
        {
            
            if(opportunityExpiredIds.contains(opportunityObject.Id))
            {
                
               // opportunityObject.addError('You cannot Close Win this Opp, since the Inventory Reserve has expired or is obsolete. Please submit a new Primary quote and start over');
            }
            
            //BSG System can close won the opportunity without docusign envelope
            if(opportunityClosedWonHopsIds.contains(opportunityObject.Id) && !opportunityDocusignCompletedIds.contains(opportunityObject.Id) && p.name <>'BSG System Administrator'    ) 
            {
                opportunityObject.addError('Docusign envelope has not been sent/completed');
            }
        }
	}
    
}