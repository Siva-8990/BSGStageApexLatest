/*******************************************************************************************
* @author           Demandblue
* @version          1.0 
* @Status           Development Completed
* @description      This class is used for generating email for Additional Quantity. 
*********************************************************************************************
Version    	Date        	Team    	Comments
*********************************************************************************************
* 1    		20 Mar 2021    	Pradeep    	Initial Development 
*********************************************************************************************/
global  class AdditionalQuantityController
{
    public Id quoteId {get;set;}
    
    global SBQQ__Quote__c getquote()
    {
		
        SBQQ__Quote__c quote = [Select Id,Org_Instance__c,Quote_Name__c,SBQQ__Status__c,SBQQ__Opportunity2__r.owner.name,Name,SBQQ__Account__r.name from SBQQ__Quote__c where Id =: quoteId];
		
        return quote;
    }
    
    public List<QuoteLineWrp> getquotelinelist()
    {
        system.debug('quoteId'+quoteId);
        list<QuoteLineWrp> quoteLineWrpList=new List<QuoteLineWrp>();
        
        Set<String> inventorySet = new Set<String>();
        
        List<SBQQ__QuoteLine__c> quotelinefromquote=[Select id,SBQQ__Quote__r.name,SBQQ__ProductCode__c,SBQQ__Product__r.ProductCode,SBQQ__Product__r.name,Crop_Year__c,SBQQ__Quantity__c from SBQQ__QuoteLine__c where SBQQ__Quote__c=:quoteId AND
                                                     Product_Category__c='Craft Brewing Contracted Hops'];
        
        
        for(SBQQ__QuoteLine__c quotelineloop:quotelinefromquote)
        {
            inventorySet.add(quotelineloop.Crop_Year__c +' - '+quotelineloop.SBQQ__ProductCode__c);
            
        }
        
        Map<Id,Inventory__c> inventoryUpdatedMap = new Map<Id,Inventory__c>(returnInventory(inventorySet));
        Map<String,Inventory__c> nameBasedInventoryMap = new Map<String,Inventory__c>();
        for(Inventory__c inventoryloop:inventoryUpdatedMap.values())
        {
            nameBasedInventoryMap.put(inventoryloop.name,inventoryloop);
        }
        
        Map<String, Decimal> AggregateDetMap = new Map<String, Decimal>();
        for (AggregateResult ar : [SELECT Crop_Year__c,SBQQ__Product__r.ProductCode, SUM(SBQQ__Quantity__c) quoteLineAggregateQty from SBQQ__QuoteLine__c where SBQQ__Quote__c=:quoteId AND Product_Category__c='Craft Brewing Contracted Hops' GROUP BY SBQQ__Product__r.ProductCode,Crop_Year__c]) 
		{
            String CropYearProductCode = ar.get('Crop_Year__c') +' - '+ar.get('ProductCode');
            AggregateDetMap.put(CropYearProductCode, (Decimal)ar.get('quoteLineAggregateQty'));
        }
		
		
        quoteLineWrpList = getquotelinelistDetails(quotelinefromquote,nameBasedInventoryMap,AggregateDetMap);
        return quoteLineWrpList;
        
    }
	
	public List<QuoteLineWrp> getquotelinelistDetails(List<SBQQ__QuoteLine__c> quotelinefromquote,Map<String,Inventory__c> nameBasedInventoryMap,Map<String, Decimal> AggregateDetMap)
    {
		list<QuoteLineWrp> quoteLineWrpList=new List<QuoteLineWrp>();
		List<String> AggregateDetMsg = new List<String>();
		for(SBQQ__QuoteLine__c quoteLineObject:quotelinefromquote)
		{
			if(nameBasedInventoryMap.containsKey(quoteLineObject.Crop_Year__c +' - '+quoteLineObject.SBQQ__Product__r.ProductCode))
			{
				if(AggregateDetMap.get(quoteLineObject.Crop_Year__c +' - '+quoteLineObject.SBQQ__Product__r.ProductCode) > nameBasedInventoryMap.get(quoteLineObject.Crop_Year__c +' - '+quoteLineObject.SBQQ__Product__r.ProductCode).Available_Volume__c && nameBasedInventoryMap.get(quoteLineObject.Crop_Year__c +' - '+quoteLineObject.SBQQ__Product__r.ProductCode).Active__c==true&& nameBasedInventoryMap.get(quoteLineObject.Crop_Year__c +' - '+quoteLineObject.SBQQ__Product__r.ProductCode).No_more_crop_available_with_Grower__c == false)
				{
					Boolean checkDupProductCropYear = AggregateDetMsg.contains(quoteLineObject.Crop_Year__c +' - '+quoteLineObject.SBQQ__Product__r.ProductCode);
					if(checkDupProductCropYear == false){
						
					
					Inventory__c inventoryRecord=nameBasedInventoryMap.get(quoteLineObject.Crop_Year__c +' - '+quoteLineObject.SBQQ__Product__r.ProductCode);
					
					quoteLineWrpList.add(new QuoteLineWrp(AggregateDetMap.get(quoteLineObject.Crop_Year__c +' - '+quoteLineObject.SBQQ__Product__r.ProductCode),quoteLineObject.SBQQ__Product__r.name,quoteLineObject.Crop_Year__c,AggregateDetMap.get(quoteLineObject.Crop_Year__c +' - '+quoteLineObject.SBQQ__Product__r.ProductCode)-inventoryRecord.Available_Volume__c) );
					AggregateDetMsg.add(quoteLineObject.Crop_Year__c +' - '+quoteLineObject.SBQQ__Product__r.ProductCode);
					}
				}
			}
		}
		return quoteLineWrpList;

	}
	
    
    
    
    public static List<Inventory__c> returnInventory(Set<string> inventoryName)
    {
        return [SELECT Id, Name, Soft_Reserve__c,Available_From__c, Hard_Reserve__c, Active__c,Total_Volume__c,No_more_crop_available_with_Grower__c, Product__c,Product__r.ProductCode, Available_Volume__c, Crop_Year__c FROM Inventory__c where Name =:inventoryName AND Active__c=True];
    }
    
   
    
    public class QuoteLineWrp{
        public decimal quantity {get;set;}
        public string productName {get;set;}
        public string cropYear {get;set;}
        public decimal actualVolume {get;set;}
        
        public QuoteLineWrp(decimal quotelinequantity,string quotelineproductname,string quotelinecropyear,decimal inventoryvolume){
          this.quantity=quotelinequantity; 
            this.productName=quotelineproductname; 
            this.cropYear=quotelinecropyear; 
            this.actualVolume=inventoryvolume; 
        }
    } 
   
    
}
