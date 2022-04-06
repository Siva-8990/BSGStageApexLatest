/*******************************************************************************************
* @author           Demandblue
* @version          1.0 
* @Status           Development Completed
* @description      This helper is used to update the most recent COVID-19 Status and called from the AccountContactedTrigger. 
*********************************************************************************************
Version    	Date        	Team    	Comments
*********************************************************************************************
* 1    		10 Apr 2020    	Vignesh    	Initial Development 
*********************************************************************************************/

public without sharing class AccountContactedHelper {
    
    public static void mostRecentCovid19Record(List<Account_Contacted__c> accountContactedList)
    {
        try{
            Map<Id,Account> accountMap = new Map<Id,Account>();
            set<Id> accountIds = new set<Id>();
            
            for(Account_Contacted__c accountContactedRecord : accountContactedList)
            {
                //Check Account available for that Account Contacted Record.
                if(String.isNotEmpty(accountContactedRecord.Account__c) || String.isNotBlank(accountContactedRecord.Account__c))
                {
                    //Add account Ids to accountIds Set.
                    accountIds.add(accountContactedRecord.Account__c);
                }
            }
            
            if(!accountIds.isEmpty())
            {
                //Query All the Accounts with Account Contacted Record where type of contact not equal to Call Attempted or Email Sent.  
                accountMap.putAll([Select Id,Name,(SELECT Account__c,Current_COVID_19_Status__c,Date_Contacted__c,Type_of_Contact__c FROM Accounts_Contacted__r  where Type_of_Contact__c != 'Call_Attempted_or_Email_Sent' ORDER BY Date_Contacted__c ASC,CreatedDate DESC) from Account where Id =: accountIds]);
				
				if(!accountMap.isEmpty())
				{
					accountMapToUpdate(accountMap);
				}
            }
  
        }
        
        
        Catch(Exception Error)
        {
            system.debug('Error Message ---> '+Error.getMessage());
        }
    }
	
	public static void accountMapToUpdate(Map<Id, Account> accountMap)
	{
		try{
			//This map is used to store all the account details to updated.
			Map<Id,Account> accountMapToUpdate = new Map<Id,Account>();
			
			for(Account accountRecord : accountMap.values())
			{
				Account accountObject = new Account();
				accountObject.id = accountRecord.id;
				
				//Using positive and negative boolean variables to check store recent status available or not.
				//Using positive and negative date variables to check recent status date.
				//Using positive and negative string variables to check recent status.
				boolean recentPositiveStatusUpdate = false;
				boolean recentNegativeStatusUpdate = false;
				string postiveStatus;
				Date postiveDateContacted;
				string negativeStatus; 
				Date negativeDateContacted;
				
				for(Account_Contacted__c accountContactedRecord : accountRecord.Accounts_Contacted__r){
					if(accountContactedRecord.Current_COVID_19_Status__c <> 'Unknown' && accountContactedRecord.Current_COVID_19_Status__c <> '' && accountContactedRecord.Current_COVID_19_Status__c <> null)
					{
						recentPositiveStatusUpdate = true;
						postiveStatus = accountContactedRecord.Current_COVID_19_Status__c;
						postiveDateContacted = accountContactedRecord.Date_Contacted__c;
						
						system.debug(accountContactedRecord);
					}
					else
					{
						recentNegativeStatusUpdate = true;
						negativeStatus = 'Unknown';
						negativeDateContacted = accountContactedRecord.Date_Contacted__c;
						
						system.debug(accountContactedRecord);
					}
					
				}
				
				if(recentPositiveStatusUpdate)
				{
					accountObject.Most_Recent_Known_COVID_19_Status1__c  = postiveStatus;
					accountObject.Date_Contacted__c = postiveDateContacted;
					
				}
				else if(recentNegativeStatusUpdate)
				{
					accountObject.Most_Recent_Known_COVID_19_Status1__c  = negativeStatus; 
					accountObject.Date_Contacted__c = negativeDateContacted;
					
			   }
				else
				{
					//If no records available store Unknown with no date of contacted.
					accountObject.Most_Recent_Known_COVID_19_Status1__c  = 'Unknown';
					accountObject.Date_Contacted__c = null;
					
				}
				
				//Add Records to map to be updated.
				accountMapToUpdate.put(accountObject.id,accountObject);
			}
			if(!accountMapToUpdate.isEmpty())
			{
				//update account.
				update accountMapToUpdate.values();
			}
		}
        
        
        Catch(Exception Error)
        {
            system.debug('Error Message ---> '+Error.getMessage());
        }

	}
    
   
    
   
}