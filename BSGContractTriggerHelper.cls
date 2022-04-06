public with sharing class BSGContractTriggerHelper {
    
    public static void duplicateBSGContractForOpportunityCheck(List<BSG_Contracts__c> bsgContractList)
    {
        
        Set<Id> opportunityIdSet = new Set<Id>();
        Set<Id> opportunityExistingList = new Set<Id>();
        for(BSG_Contracts__c BSGContractsRecord : bsgContractList)
        {
            opportunityIdSet.add(BSGContractsRecord.Opportunity__c);
        }
        
        if(!opportunityIdSet.isEmpty())
        {
            Map<Id,BSG_Contracts__c> bsgContractsMap = new Map<Id,BSG_Contracts__c>([Select Id,Opportunity__c from BSG_Contracts__c where Opportunity__c =: opportunityIdSet]);
            for(BSG_Contracts__c BSGContractsRecord : bsgContractsMap.values())
            {
                opportunityExistingList.add(BSGContractsRecord.Opportunity__c);
            }
            duplicateBSGContractForOpportunityCheckMethod(bsgContractList,opportunityExistingList,bsgContractsMap); 
		}
		
		      
    }
	public static void duplicateBSGContractForOpportunityCheckMethod(List<BSG_Contracts__c> bsgContractList,Set<Id> opportunityExistingList,Map<Id,BSG_Contracts__c> bsgContractsMap){
		for(BSG_Contracts__c BSGContractsRecord : bsgContractList)
		{
			if(opportunityExistingList.contains(BSGContractsRecord.Opportunity__c))
			{
				if(BSGContractsRecord.id != null){
					if(bsgContractsMap.containsKey(BSGContractsRecord.Id) && bsgContractsMap.get(BSGContractsRecord.Id).Opportunity__c <> BSGContractsRecord.Opportunity__c)
					{
						BSGContractsRecord.addError('There can only be one  BSG Contract associated to an Opportunity');
					} 
				}
				else
				{
					BSGContractsRecord.addError('There can only be one  BSG Contract associated to an Opportunity');
				}
				
			}
		}
	}
    
}