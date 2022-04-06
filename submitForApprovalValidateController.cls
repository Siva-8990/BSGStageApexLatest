/*******************************************************************************************
* @author           Demandblue
* @version          1.0 
* @Status           Development Completed
* @description      This class is used to override submit for approval functionality. 
*********************************************************************************************
Version    	Date        	Team    	Comments
*********************************************************************************************
* 1    		20 Mar 2021    	Vignesh    	Initial Development 
*********************************************************************************************/
public without sharing class submitForApprovalValidateController {
    
    public static List<String> approvalProcessNames = new List<String>{'BSG_Quotation_Auto_Rejected_Process_NZHL','BSG_Quotation_Auto_Approval_Process','BSG_Quotation_Approval_Process3'/*'BSG_Quotation_Auto_Approval_Process','BSG_Quotation_Approval_Process3','BSG_Quotation_Auto_Rejected_Process_NZHL','BSG_Quotation_Auto_Approval_Process_Hops','BSG_Quotation_Approval_Process_Hops','BSG_Quotation_Auto_Approval_Process_NZHL','BSG_Quotation_Approval_Process_NZHL'*/};
    //public static List<String> approvalProcessNames = new List<String>{'BSG_Quotation_Auto_Approval_Process','BSG_Quotation_Approval_Process3','BSG_Quotation_Auto_Approval_Process_Hops','BSG_Quotation_Approval_Process_Hops','BSG_Quotation_Auto_Approval_Process_NZHL','BSG_Quotation_Approval_Process_NZHL'};
        public static Integer approvalOrder = 0;  
    
    @AuraEnabled
    public static String validateBeforeApprovalProcess(Id recordId)
    {
        String messageToReturn = 'Success';
        try{
            List<Messaging.SingleEmailMessage> sendEmailToAddCrop = new List<Messaging.SingleEmailMessage>();
            SBQQ__Quote__c quote = [Select id,SBQQ__Primary__c,SBQQ__StartDate__c from SBQQ__Quote__c where Id =: recordId];
            
            
            if(quote.SBQQ__Primary__c)
            {
                if(quote.SBQQ__StartDate__c < system.Today()){
                    messageToReturn = 'Start date should be greater than or equal to today.';
                    return messageToReturn;
                }
                Set<string> inventorySet = new Set<String>();
                Set<string> inventoryNameSet = new Set<String>();
                
                Map<Id,SBQQ__QuoteLine__c> quoteLineMap = new Map<Id,SBQQ__QuoteLine__c>([SELECT Name,Crop_Year__c,Product_Category__c,Start_Date_Non_Rahr__c,SBQQ__Quote__r.Quote_Name__c,SBQQ__Quantity__c,SBQQ__ProductName__c,SBQQ__Quote__c,SBQQ__Quote__r.Id,SBQQ__Quote__r.SBQQ__Opportunity2__c,SBQQ__Quote__r.SBQQ__Account__c,SBQQ__Quote__r.SBQQ__Account__r.name,SBQQ__Product__c,SBQQ__Product__r.ProductCode,SBQQ__Product__r.Name FROM SBQQ__QuoteLine__c where SBQQ__Quote__c =:  quote.Id AND (Product_Category__c = 'Craft Brewing Contracted Hops' OR Product_Category__c = 'Craft Brewing Hops')]);
                Map<Id,SBQQ__QuoteLine__c> quoteLineMapDate = new Map<Id,SBQQ__QuoteLine__c>([SELECT Name,Crop_Year__c,Available_Quantity__c,SBQQ__Product__r.ProductCode,Product_Category__c,Start_Date_Non_Rahr__c FROM SBQQ__QuoteLine__c where SBQQ__Quote__c =:  quote.Id AND (Product_Category__c = 'Craft Brewing Contracted Hops' OR Product_Category__c = 'Non-Rahr Bulk' OR Product_Category__c = 'Craft Brewing Hops')]);
               	Map<Id,SBQQ__QuoteLine__c> quoteLineMapRahr = new Map<Id,SBQQ__QuoteLine__c>([SELECT Name,Crop_Year__c,Available_Quantity__c,SBQQ__Product__r.ProductCode,Product_Category__c,Start_Date_Non_Rahr__c,Trucking_Cost_per_unit__c,Price_TBD__c FROM SBQQ__QuoteLine__c where SBQQ__Quote__c =:  quote.Id AND (Product_Category__c = 'Rahr Bulk' )]);

               
                
                
                     messageToReturn = validateBeforeApprovalProcessForStartDateAndInventory(recordId,quote,messageToReturn,quoteLineMapDate,inventoryNameSet);
                     messageToReturn = validateBeforeApprovalProcessForInventory(recordId,quote,messageToReturn,inventorySet,quoteLineMapDate);
                
                     messageToReturn = validateBeforeApprovalProcessForOfftakes(recordId,quote,messageToReturn,quoteLineMapRahr);
					messageToReturn = validateBeforeApprovalProcessForTruckingCost(recordId,quote,quoteLineMapRahr,messageToReturn);
               
                if(!quoteLineMap.isEmpty())
                {
                    for(SBQQ__QuoteLine__c quoteLineObject : quoteLineMap.values())
                    {
                        inventorySet.add(quoteLineObject.Crop_Year__c +' - '+quoteLineObject.SBQQ__Product__r.ProductCode);                        
                    }
                }
               
				messageToReturn = validateBeforeApprovalProcessForWishList(recordId,quote,messageToReturn,quoteLineMap,inventorySet,sendEmailToAddCrop);
                
               
            }
            
            else
            {
                messageToReturn = 'Only Primary Quote can be Submitted for Approval'; 
                if(quote.SBQQ__StartDate__c < system.Today()){
                    messageToReturn += ' and Start date should be greater than or equal to today.';                    
                }
            }
                    
            
        }
        

        catch(Exception error)
        {
            messageToReturn = error.getMessage();
        }
        
        
        return messageToReturn;
    }
	public static String validateBeforeApprovalProcessForStartDateAndInventory(Id recordId,SBQQ__Quote__c quote,String messageToReturn,Map<Id,SBQQ__QuoteLine__c> quoteLineMapDate,Set<string> inventoryNameSet){
        system.debug('Checkmethod');
		//String messageToReturn = 'Success';
		try{
	 if(quote.SBQQ__Primary__c)
            {
	
	 if(!quoteLineMapDate.isEmpty())
                {
                    for(SBQQ__QuoteLine__c quoteLineObjectDate : quoteLineMapDate.values())
                    {
                        if(quote.SBQQ__StartDate__c > quoteLineObjectDate.Start_Date_Non_Rahr__c){
                            messageToReturn = 'Quote Line Start Date should be greater or equal to the Quote Start Date.';
                            return messageToReturn;
                        }
                        if((quoteLineObjectDate.Product_Category__c == 'Craft Brewing Hops' || quoteLineObjectDate.Product_Category__c == 'Craft Brewing Contracted Hops')){
                            inventoryNameSet.add(quoteLineObjectDate.Crop_Year__c +' - '+quoteLineObjectDate.SBQQ__Product__r.ProductCode);
                        }
                        if(((quoteLineObjectDate.Product_Category__c == 'Craft Brewing Hops' || quoteLineObjectDate.Product_Category__c == 'Craft Brewing Contracted Hops') && string.isBlank(quoteLineObjectDate.Crop_Year__c)) || (quoteLineObjectDate.Product_Category__c == 'Craft Brewing Contracted Hops' && string.isBlank(String.valueOf(quoteLineObjectDate.Available_Quantity__c)))){
                            messageToReturn = 'Inventory is not available for this Crop year or the Crop year has not been selected or the Inventory record has not been created for this product.';
                            return messageToReturn;
                        }                        
                    }
               
                } 
				}
				}
				catch(Exception error)
        {
            messageToReturn = error.getMessage();
        }
        
        
        return messageToReturn;
    }
				
	public static String validateBeforeApprovalProcessForInventory(Id recordId,SBQQ__Quote__c quote,String messageToReturn,Set<string> inventoryNameSet,Map<Id,SBQQ__QuoteLine__c> quoteLineMapDate){
        system.debug('Checkmethod');
		//String messageToReturn = 'Success';
		try{
	 if(quote.SBQQ__Primary__c)
            {
	
	      if(!inventoryNameSet.isEmpty() && !quoteLineMapDate.isEmpty()){
                        Map<Id,Inventory__c> inventoryCropYearMap = new Map<Id,Inventory__c>([SELECT Id, Name, Available_From__c, Soft_Reserve__c, Hard_Reserve__c, Active__c,Total_Volume__c,No_more_crop_available_with_Grower__c, Product__c,Product__r.ProductCode, Available_Volume__c, Crop_Year__c FROM Inventory__c where Name =:inventoryNameSet]);
                        Map<String,Inventory__c> nameBasedInventoryCropYearMap = new Map<String,Inventory__c>();
                        if(inventoryCropYearMap.isEmpty())
                        {
                            messageToReturn = 'Inventory is not available for this Crop year or the Crop year has not been selected or the Inventory record has not been created for this product.';
                            return messageToReturn;
                        }
                        for(Inventory__c inventoryRecord : inventoryCropYearMap.values())
                        {
                            nameBasedInventoryCropYearMap.put(inventoryRecord.name,inventoryRecord);
                        }
                        //for(SBQQ__QuoteLine__c quoteLineObjectRecord : quoteLineMapDate.values())
                        for(String inventoryName:inventoryNameSet)
                        {
                            if(!nameBasedInventoryCropYearMap.containsKey(inventoryName))
                            {
                                messageToReturn = 'Inventory is not available for this Crop year or the Crop year has not been selected or the Inventory record has not been created for this product.';
                                return messageToReturn;
                            }
                        }
                    }
					}
					}
					catch(Exception error)
        {
            messageToReturn = error.getMessage();
        }
        
        
        return messageToReturn;
    }


	public static String validateBeforeApprovalProcessForOfftakes(Id recordId,SBQQ__Quote__c quote,String messageToReturn,Map<Id,SBQQ__QuoteLine__c> quoteLineMapRahr){
        system.debug('Checkmethod');
		//String messageToReturn = 'Success';
		try{
	 if(quote.SBQQ__Primary__c)
            {
				 //Map<Id,SBQQ__QuoteLine__c> quoteLineMapRahr = new Map<Id,SBQQ__QuoteLine__c>([SELECT Name,Crop_Year__c,Available_Quantity__c,SBQQ__Product__r.ProductCode,Product_Category__c,Start_Date_Non_Rahr__c,Trucking_Cost_per_unit__c,Price_TBD__c FROM SBQQ__QuoteLine__c where SBQQ__Quote__c =:  quote.Id AND (Product_Category__c = 'Rahr Bulk' )]);
               Map<Id,Offtake__c> OfftakeRec = new Map<Id,Offtake__c>([SELECT Id,Quote_Line__r.SBQQ__StartDate__c,Quote_Line__r.SBQQ__EndDate__c,QuoteLine_Qty__c,Quote_Line__r.SBQQ__Product__r.Name,Total_Offtake_Qty__c,End_Date__c,Start_Date__c,Unit__c,Jan__c,Feb__c,Mar__c,Apr__c,May__c,Jun__c,Jul__c,Aug__c,Sep__c,Oct__c,Nov__c,Dec__c
               FROM Offtake__c where Quote_Line__c IN:  quoteLineMapRahr.Keyset()]);
			   if(!quoteLineMapRahr.isEmpty())
                 {

                     if(quoteLineMapRahr.size() !=OfftakeRec.size() ){
                      messageToReturn = 'Please ensure you have an offtake entered for each Rahr Bulk quote line and the Total Offtake Quantity = Total Quantity for each year';
                          return messageToReturn;
                     }
                     
                     
                    if(!OfftakeRec.isEmpty())
                {
                   for(Offtake__c offtakeqty : OfftakeRec.values())
                   {
                       if(offtakeqty.Total_Offtake_Qty__c != offtakeqty.QuoteLine_Qty__c)
                       {
                           messageToReturn = 'Please ensure that Total Offtake Quantity = QuoteLine Quantity for each year';
                       }
                   }
                }
                   
                 }
                  
			}
		}
    catch(Exception error)
        {
            messageToReturn = error.getMessage();
        }
        
        
        return messageToReturn;
    }
	public static String validateBeforeApprovalProcessForTruckingCost(Id recordId,SBQQ__Quote__c quote,Map<Id,SBQQ__QuoteLine__c> quoteLineMapRahr,String messageToReturn){
	 system.debug('Checkmethod');
		//String messageToReturn = 'Success';
		try{
	 if(quote.SBQQ__Primary__c)
            {
	 for(SBQQ__QuoteLine__c quoteline : quoteLineMapRahr.values())
                   {
                       if(quoteline.Trucking_Cost_per_unit__c == 0 && quoteline.Price_TBD__c == False)
                       {
                          messageToReturn = 'Please hit calculate on the Quote Line Editor to recalculate the prices';
                          return messageToReturn;
                       }
                   }
				   }
				   }
				   catch(Exception error)
        {
            messageToReturn = error.getMessage();
        }
        
        
        return messageToReturn;
    }
	public static String validateBeforeApprovalProcessForWishList(Id recordId,SBQQ__Quote__c quote,String messageToReturn,Map<Id,SBQQ__QuoteLine__c> quoteLineMap,Set<string> inventorySet,List<Messaging.SingleEmailMessage> sendEmailToAddCrop){
        system.debug('Check WIshlist');
		
        try{
			if(quote.SBQQ__Primary__c)
            {
				Map<String,Date> Availablefrommap =new map<String,Date>();
                if(!quoteLineMap.isEmpty()){
                    Map<Id,Inventory__c> inventoryMap = new Map<Id,Inventory__c>([SELECT Id, Name, Available_From__c, Soft_Reserve__c, Hard_Reserve__c, Active__c,Total_Volume__c,No_more_crop_available_with_Grower__c, Product__c,Product__r.ProductCode, Available_Volume__c, Crop_Year__c FROM Inventory__c where Name =:inventorySet]);
                    Map<String,Inventory__c> nameBasedInventoryMap = new Map<String,Inventory__c>();
                    
                    for(Inventory__c inventoryObject : inventoryMap.values())
                    {
                        nameBasedInventoryMap.put(inventoryObject.name,inventoryObject);
                        Availablefrommap.put(inventoryObject.Crop_Year__c,inventoryObject.Available_From__c);
                    }
				Set<id> quoteIdList=new set<id>();                    
                    Integer index = 1;
                    Boolean isWishList = false;
                    Map<String, Decimal> newMap = new Map<String, Decimal>();
                    for(SBQQ__QuoteLine__c quoteLineObject : quoteLineMap.values())
                    {
                        Decimal QuoteQtyAggregate =0;
                        if(quoteLineObject.Start_Date_Non_Rahr__c < Availablefrommap.get(quoteLineObject.Crop_Year__c))
                        {
                            Datetime Availablefromdate = Availablefrommap.get(quoteLineObject.Crop_Year__c);
                            messageToReturn = quoteLineObject.Crop_Year__c+' '+ quoteLineObject.SBQQ__ProductName__c  +' is available from '+ Availablefromdate.format('MM-dd-yyyy','GMT') + '. This Quote cannot be Submitted for Approval, unless the Quote Start Date is after this Crop\'s Available date.';
                            return messageToReturn;
                        }                        
                        if(nameBasedInventoryMap.containsKey(quoteLineObject.Crop_Year__c +' - '+quoteLineObject.SBQQ__Product__r.ProductCode))
                        {
                            if(newMap.containsKey(quoteLineObject.Crop_Year__c +' - '+quoteLineObject.SBQQ__Product__r.ProductCode))
                            {
                                QuoteQtyAggregate = newMap.get(quoteLineObject.Crop_Year__c +' - '+quoteLineObject.SBQQ__Product__r.ProductCode) + quoteLineObject.SBQQ__Quantity__c;
                                newMap.put(quoteLineObject.Crop_Year__c +' - '+quoteLineObject.SBQQ__Product__r.ProductCode, QuoteQtyAggregate);
                            }else
                            {
                                newMap.put(quoteLineObject.Crop_Year__c +' - '+quoteLineObject.SBQQ__Product__r.ProductCode, quoteLineObject.SBQQ__Quantity__c);
                            }
                            
                             messageToReturn = validateBeforeApprovalProcessForInsufficientAvailability(recordId,quote,messageToReturn,quoteLineMap,nameBasedInventoryMap,isWishList,index,newMap,quoteIdList);
							 messageToReturn = validateBeforeApprovalProcessForAdditionalCrop(recordId,quote,messageToReturn,quoteLineMap,nameBasedInventoryMap,isWishList,index,newMap);
                          
                            
                        }
                    }
                            
                   // messageToReturn.split('\n');
                    
                    for(id quoteid:quoteIdList){
                        sendEmailToAddCrop.add(returnEmailMessage(quoteid));
                        
                    }
                    
                    if(!sendEmailToAddCrop.isEmpty())
                    {
                        
                        Messaging.SendEmailResult[] results = Messaging.sendEmail(sendEmailToAddCrop);
                    }
                    
                }
            }
		}
			catch(Exception error)
        {
            messageToReturn = error.getMessage();
        }
        
        
        return messageToReturn;
    }
    public static String validateBeforeApprovalProcessCreateWishList(Boolean isWishList,String messageToReturn){
     if(isWishList){
                        if(!messageToReturn.contains('Do you want to create a wishlist record for this Product(s)?')){
                        messageToReturn = messageToReturn +'<br/>'  +' Do you want to create a wishlist record for this Product(s)?'+'<br/>';
                        }
                    }
         return messageToReturn;
    }
	public static String validateBeforeApprovalProcessForInsufficientAvailability(Id recordId,SBQQ__Quote__c quote,String messageToReturn,Map<Id,SBQQ__QuoteLine__c> quoteLineMap,Map<String,Inventory__c> nameBasedInventoryMap,Boolean isWishList,Integer index,Map<String, Decimal> newMap,Set<id> quoteIdList){
        try{
			if(quote.SBQQ__Primary__c)
            {
        //String messageToReturn = 'Success';
        for(SBQQ__QuoteLine__c quoteLineObject : quoteLineMap.values()){
	
	if(nameBasedInventoryMap.get(quoteLineObject.Crop_Year__c +' - '+quoteLineObject.SBQQ__Product__r.ProductCode).No_more_crop_available_with_Grower__c == False && nameBasedInventoryMap.get(quoteLineObject.Crop_Year__c +' - '+quoteLineObject.SBQQ__Product__r.ProductCode).Active__c==true && (quoteLineObject.SBQQ__Quantity__c > nameBasedInventoryMap.get(quoteLineObject.Crop_Year__c +' - '+quoteLineObject.SBQQ__Product__r.ProductCode).Available_Volume__c || newMap.get(quoteLineObject.Crop_Year__c +' - '+quoteLineObject.SBQQ__Product__r.ProductCode) > nameBasedInventoryMap.get(quoteLineObject.Crop_Year__c +' - '+quoteLineObject.SBQQ__Product__r.ProductCode).Available_Volume__c))
                            {
                                
                                isWishList = true;
                                quoteIdList.add(quoteLineObject.SBQQ__Quote__r.id);
                                if(!messageToReturn.contains(quoteLineObject.Crop_Year__c+' '+quoteLineObject.SBQQ__Product__r.Name)){
                                    if(messageToReturn == 'Success'){
                                        messageToReturn = index +'.There is insufficient availability of'+' '+quoteLineObject.Crop_Year__c+' '+quoteLineObject.SBQQ__Product__r.Name+'.  A notification has been sent to the Hops Team to procure additional volume for contracting.  Kindly re-submit for approval when additional product is available, or create a new Quote with sufficient availability.'+'<br/>';
                                    }
                                    else
                                    {
                                        messageToReturn = messageToReturn  +' ' +index +'.There is insufficient availability of'+' '+quoteLineObject.Crop_Year__c+' '+quoteLineObject.SBQQ__Product__r.Name+'.  A notification has been sent to the Hops Team to procure additional volume for contracting.  Kindly re-submit for approval when additional product is available, or create a new Quote with sufficient availability.'+'<br/>';
                                    }
                                    index = index+1;
                                }
                            }
							}
                messageToReturn = validateBeforeApprovalProcessCreateWishList(isWishList,messageToReturn);
                
            }
    }
        catch(Exception error)
        {
            messageToReturn = error.getMessage();
        }
        
        
        return messageToReturn;
    }
	public static String validateBeforeApprovalProcessForAdditionalCrop(Id recordId,SBQQ__Quote__c quote,String messageToReturn,Map<Id,SBQQ__QuoteLine__c> quoteLineMap,Map<String,Inventory__c> nameBasedInventoryMap,Boolean isWishList,Integer index,Map<String, Decimal> newMap){
        try{
			if(quote.SBQQ__Primary__c)
            {
        //String messageToReturn = 'Success';
        for(SBQQ__QuoteLine__c quoteLineObject : quoteLineMap.values()){
	 if(nameBasedInventoryMap.get(quoteLineObject.Crop_Year__c +' - '+quoteLineObject.SBQQ__Product__r.ProductCode).No_more_crop_available_with_Grower__c == true && nameBasedInventoryMap.get(quoteLineObject.Crop_Year__c +' - '+quoteLineObject.SBQQ__Product__r.ProductCode).Active__c==true && (quoteLineObject.SBQQ__Quantity__c > nameBasedInventoryMap.get(quoteLineObject.Crop_Year__c +' - '+quoteLineObject.SBQQ__Product__r.ProductCode).Available_Volume__c || newMap.get(quoteLineObject.Crop_Year__c +' - '+quoteLineObject.SBQQ__Product__r.ProductCode) > nameBasedInventoryMap.get(quoteLineObject.Crop_Year__c +' - '+quoteLineObject.SBQQ__Product__r.ProductCode).Available_Volume__c) )
                            {      
                                isWishList = true;   
                                if(!messageToReturn.contains(quoteLineObject.Crop_Year__c+' '+quoteLineObject.SBQQ__Product__r.Name)){
                                if(messageToReturn == 'Success'){
                                    messageToReturn = index +'.Additional crop cannot be procured for this year, for the Product : '+quoteLineObject.Crop_Year__c+' '+quoteLineObject.SBQQ__Product__r.Name+', please ensure quantity is less than or equal to the Available quantity for this Crop year?'+'<br/>';
                                }
                                else
                                {
                                    messageToReturn = messageToReturn  +' ' +index +'.Additional crop cannot be procured for this year, for the Product : '+quoteLineObject.Crop_Year__c+' '+quoteLineObject.SBQQ__Product__r.Name+', please ensure quantity is less than or equal to the Available quantity for this Crop year?'+'<br/>';
                                }
                                index = index+1;
                                }
                            }
							}
                 messageToReturn = validateBeforeApprovalProcessCreateWishList(isWishList,messageToReturn);
                      
            }
    }
        catch(Exception error)
        {
            messageToReturn = error.getMessage();
        }
        
        
        return messageToReturn;
    }
            
	
	
    
    @AuraEnabled
    public static String checkApprovalProcessApplicable(Id recordId,String comments)
    {
        try{
            SBQQ__Quote__c Quote=[select id,SBQQ__Status__c from SBQQ__Quote__c where Id=:recordId];
            //String profileName =[SELECT Id, profile.Name FROM User WHERE Id =:UserInfo.getUserId()].profile.Name;
            
            if(quote.SBQQ__Status__c=='Approved' ){
                
                return 'Already Approved';
            }
            
            if(Quote.SBQQ__Status__c!='Approved'){
                
                
                Approval.ProcessResult result = sendForApproval(recordId,comments,approvalProcessNames[approvalOrder]);
                
                if(result.isSuccess())
                {
                    return  'SUCCESS';
                }
                
                
                
            }
            
        }catch (exception error){
            
            if(error.getMessage().contains('NO_APPLICABLE_PROCESS'))
            {
                
                
                approvalOrder = approvalOrder + 1;
                if(approvalOrder < approvalProcessNames.size())
                {
                    try{
                        return checkApprovalProcessApplicable(recordId,comments);
                    }
                    catch(Exception errorEx)
                    {
                        return errorEx.getMessage();
                    }
                }
                
            }
            return 'Something Went Wrong';
            
        }
        return 'Success';            
    }
    
    public static Approval.ProcessResult sendForApproval(Id recordId,String comments,String approvalProcessName )
    {
        
        Approval.ProcessSubmitRequest approvalRequest = new Approval.ProcessSubmitRequest();
        approvalRequest.setComments('Submitting request for approval.');
        approvalRequest.setObjectId(recordId);
        approvalRequest.setComments(comments);
        approvalRequest.setProcessDefinitionNameOrId(approvalProcessName);
        Approval.ProcessResult result = Approval.process(approvalRequest);
        system.debug('result'+result);
        return result;
    }
    
    public static Messaging.SingleEmailMessage returnEmailMessage(Id quoteLineObject)
    {
        
        EmailTemplate template=[SELECT Id,htmlValue,Body,Subject FROM EmailTemplate WHERE DeveloperName = 'Notifications_for_Additional_Quantity'];
        SBQQ__Quote__c quote=[select id,SBQQ__PrimaryContact__c,SBQQ__SalesRep__c,SBQQ__SalesRep__r.Email from SBQQ__Quote__c where id=:quoteLineObject];
        
        List<String> addAdditionalEmail = new List<String>();
        List<String> addAdditionalEmailforHopsTeam = new List<String>();
        if(system.label.Malissia_s_Email != null)
        {
            addAdditionalEmail.add(system.label.Malissia_s_Email);
        }
        
        
        if(quote.SBQQ__SalesRep__c != null && quote.SBQQ__SalesRep__r.Email != null)
        {
            addAdditionalEmail.add(quote.SBQQ__SalesRep__r.Email);
        }
        
        if(system.label.Laura_s_Email != null)
        {
            addAdditionalEmailforHopsTeam.add(system.label.Laura_s_Email);
        }
        
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        mail.setToAddresses(addAdditionalEmailforHopsTeam);   
        
        
        mail.setSaveAsActivity(false);
        mail.setTemplateId(template.id);
        
        mail.setTargetObjectId(system.label.Notification_Email_for_Additional_Quantity);
        mail.setWhatId(quoteLineObject);
        
        if(!addAdditionalEmail.isEmpty())
        {
            
            mail.setCcAddresses(addAdditionalEmail);
        }
        mail.setSenderDisplayName('BSG Admin'); 
        
        
        return mail;
        
    }
    
    
}