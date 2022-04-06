/*******************************************************************************************
* @Author           Demandblue
* @Version          1.0 
* @Status           Development Completed
* @Class Name       WaitlistDetailsPerQuoteController
* @Description      This class fetches wishlist details based on Quote or Account
*********************************************************************************************
Version    	Date        	Team    		Comments
*********************************************************************************************
* 1.0    	24-JUN-2021    	Demandblue    	Initial Development 
*********************************************************************************************/
public with sharing class WaitlistDetailsPerQuoteController {    
    /**************************************************************************************
  * @Description  This method will fetch quote lines
  * @Param		quoteId - Id of quote
  * @Return       WaitlistWrapper - waitlist wrapper class
  **************************************************************************************/         
      @AuraEnabled
      public static void saveQuoteDetails(List<WaitlistWrapper> lstWrapper) {
          //List<WaitlistWrapper> lstWrapper = (List<WaitlistWrapper>) JSON.deserialize(JSON.serialize(lstWrapperdata),List<WaitlistWrapper>.class);
          List<Waitlist__c> lstWaitlist = new List<Waitlist__c>();
          List<Waitlist__c> updateWishlist = new List<Waitlist__c>();
          Set<String> inventorySet = new Set<String>();
          Map<String, Inventory__c> mapInventory = new Map<String, Inventory__c>();
          system.debug('lstWrapper.size::::' + lstWrapper.size());
          system.debug('lstWrapper::::' + lstWrapper);
          for(WaitlistWrapper wrapper : lstWrapper) {
              inventorySet.add(wrapper.inventoryYear + ' - '+ wrapper.productCode);
          }
          
          for(Inventory__c inventoryRecord : [SELECT Id, Name FROM Inventory__c WHERE Name IN :inventorySet AND Active__c=True]) {
              mapInventory.put(inventoryRecord.Name, inventoryRecord);
          }
          
          for(WaitlistWrapper wrapper : lstWrapper) {
              Waitlist__c waitlistRecord = new Waitlist__c(Active__c = true);
              waitlistRecord.Account__c = wrapper.accountId;
              waitlistRecord.Inventory_Year__c = wrapper.inventoryYear;
              waitlistRecord.Opportunity__c = wrapper.opportunityId;
              waitlistRecord.Product__c = wrapper.productId;
              waitlistRecord.Quantity__c = wrapper.waitlistQuantity;
              waitlistRecord.Inventory__c = mapInventory.containsKey(wrapper.inventoryYear + ' - '+ wrapper.productCode) ? mapInventory.get(wrapper.inventoryYear + ' - '+ wrapper.productCode).Id : NULL;
              waitlistRecord.Quote__c = wrapper.quoteId;
              waitlistRecord.Quote_Line__c = wrapper.quoteLineId;
              waitlistRecord.Unit__c = wrapper.unit;
              if(string.IsNotBlank(wrapper.waitlistId)){
                  waitlistRecord.Id = wrapper.waitlistId;
                  updateWishlist.add(waitlistRecord);
              }else{
                  lstWaitlist.add(waitlistRecord);
              }
          }
          if(!lstWaitlist.isEmpty())
              insert lstWaitlist;
          if(!updateWishlist.isEmpty())
              update updateWishlist;
      }
      @AuraEnabled(cacheable=true)
      public static List<WaitlistWrapper> getAccountDetails(Id accountId) {
          List<WaitlistWrapper> wrapper = new List<WaitlistWrapper>();
          List<Waitlist__c> waitList = [SELECT Id,Name,Account__c,Account__r.Name,Opportunity__c,Opportunity__r.Name,Quote__c,Quote__r.Name,
                                        Quote_Line__c,Quote_Line__r.Name,Product__c,Product__r.Name,Product__r.productCode,Quantity__c,
                                        Inventory__c,Inventory__r.Name,Inventory_Year__c,Active__c,Unit__c,Wishlist_Product__c,Product_Format__c,Other_Product_Format__c,Other_Wishlist_Product__c,Inactive_Reason_Code__c
                                        FROM Waitlist__c where Account__c =: accountId ORDER BY CreatedDate];
          for(Waitlist__c waitListRec : waitList) {   
              String accName = String.isNotBlank(waitListRec.Account__c) ? waitListRec.Account__r.Name : '';
              String oppName = String.isNotBlank(waitListRec.Opportunity__c) ? waitListRec.Opportunity__r.Name : '';
              String productName = String.isNotBlank(waitListRec.Product__c) ? waitListRec.Product__r.Name : '';
              String inventoryYr = String.isNotBlank(waitListRec.Inventory_Year__c) ? waitListRec.Inventory_Year__c : '';
              Decimal waitlistQuantity = waitListRec.Quantity__c != NULL ? waitListRec.Quantity__c : NULL;
              String unit = String.isNotBlank(waitListRec.Unit__c) ? waitListRec.Unit__c : '';
              wrapper.add(new WaitlistWrapper(waitListRec.Account__c, accName, waitListRec.Opportunity__c, oppName, waitListRec.Quote__c, waitListRec.Quote__r.Name, waitListRec.Quote_Line__c, waitListRec.Product__c, productName, waitListRec.Product__r.ProductCode, inventoryYr, waitlistQuantity, unit, waitListRec.Active__c, waitListRec.Wishlist_Product__c,waitListRec.Id,waitListRec.Product_Format__c,waitListRec.Other_Product_Format__c,'action:edit','Edit',waitListRec.Other_Wishlist_Product__c,waitListRec.Inactive_Reason_Code__c));
          }
          //system.debug('wrapper' + wrapper);
          return wrapper;                                      
      }
      @AuraEnabled(cacheable=true)
      public static WaitlistWrapper getWaitlistDetailsForEdit(Id RecordId){
          WaitlistWrapper wrapper = new WaitlistWrapper();
          String sObjName = RecordId.getSObjectType().getDescribe().getName();        
          if(sObjName == 'Account'){
              wrapper = new WaitlistWrapper(RecordId,'',null,'',null,'',null,null,'','','',decimal.valueOf('0'),'',false,'','','','','','','','');
          }
          if(sObjName == 'SBQQ__Quote__c'){
              List<SBQQ__Quote__c> newQuote = [SELECT Id,Name,SBQQ__Opportunity2__c,SBQQ__Account__c FROM SBQQ__Quote__c WHERE ID =:RecordId LIMIT 1];
              wrapper = new WaitlistWrapper(newQuote[0].SBQQ__Account__c,'',newQuote[0].SBQQ__Opportunity2__c,'',RecordId,'',null,null,'','','',decimal.valueOf('0'),'',false,'','','','','','','','');
          }        
          return wrapper;
      }
      @AuraEnabled(cacheable=true)
      public static List<WaitlistWrapper> getWaitlistDetails(Id RecordId){
          List<WaitlistWrapper> wrapper = new List<WaitlistWrapper>();
          String sObjName = RecordId.getSObjectType().getDescribe().getName();
          system.debug('sObjName::::'+ sObjName);
          system.debug('RecordId::::'+ RecordId);
          if(sObjName == 'Account'){
              wrapper = getAccountDetails(RecordId);
              //wrapper.addall(getWishListRecordsFromAccount(RecordId));
          }
          if(sObjName == 'SBQQ__Quote__c'){
              wrapper = getWaitListDetailsForQuote(RecordId);
              system.debug('wrapper::::'+ wrapper.size());
              List<WaitlistWrapper> wrapperForLoop = new List<WaitlistWrapper>();
              wrapperForLoop.addAll(wrapper);
              List<WaitlistWrapper> wrapperNew = getWishListRecordsFromQuoteLine(new List<string>{RecordId});
              //wrapper.addAll(wrapperNew);
              if(!wrapperForLoop.isEmpty() && !wrapperNew.isEmpty())
              {
                  for(WaitlistWrapper fromQuoteLine : wrapperNew){
                      boolean isRecordValid = false;
                      for(WaitlistWrapper fromWishListRec : wrapperForLoop){
                          if(fromWishListRec.productId != null){
                              //isRecordValid = true;            
                              if(fromWishListRec.productId == fromQuoteLine.productId && fromWishListRec.inventoryYear == fromQuoteLine.inventoryYear)
                              {
                                  isRecordValid = true;
                                  Break;
                              }
  
                              /*if(fromWishListRec.productId == fromQuoteLine.productId && fromWishListRec.inventoryYear != fromQuoteLine.inventoryYear){
                                  wrapper.add(fromQuoteLine);
                                  Break;
                              }
                              else if(fromWishListRec.productId != fromQuoteLine.productId)
                              {
                                  wrapper.add(fromQuoteLine);
                                  Break;
                              }*/
                          }
                      }
                      if(!isRecordValid){
                          wrapper.add(fromQuoteLine);
                      }
                  }
              }
              else if(!wrapperNew.isEmpty()){
                  wrapper.addAll(wrapperNew);
              }
          }
          system.debug('wrapper::::'+ wrapper);
          return wrapper;
      }
      @AuraEnabled(cacheable=true)
      public static List<WaitlistWrapper> getWaitListDetailsForQuote(Id quoteId) {
          List<WaitlistWrapper> wrapper = new List<WaitlistWrapper>();
          List<Waitlist__c> waitList = [SELECT Id,Name,Account__c,Account__r.Name,Opportunity__c,Opportunity__r.Name,Quote__c,Quote__r.Name,
                                        Quote_Line__c,Quote_Line__r.Name,Product__c,Product__r.Name,Product__r.productCode,Quantity__c,
                                        Inventory__c,Inventory__r.Name,Inventory_Year__c,Active__c,Unit__c,Wishlist_Product__c,Product_Format__c,Other_Product_Format__c,Other_Wishlist_Product__c,Inactive_Reason_Code__c
                                        FROM Waitlist__c where Quote__c =: quoteId ORDER BY CreatedDate];
          for(Waitlist__c waitListRec : waitList) {   
              String accName = String.isNotBlank(waitListRec.Account__c) ? waitListRec.Account__r.Name : '';
              String oppName = String.isNotBlank(waitListRec.Opportunity__c) ? waitListRec.Opportunity__r.Name : '';
              String productName = String.isNotBlank(waitListRec.Product__c) ? waitListRec.Product__r.Name : '';
              String inventoryYr = String.isNotBlank(waitListRec.Inventory_Year__c) ? waitListRec.Inventory_Year__c : '';
              Decimal waitlistQuantity = waitListRec.Quantity__c != NULL ? waitListRec.Quantity__c : NULL;
              String unit = String.isNotBlank(waitListRec.Unit__c) ? waitListRec.Unit__c : '';
              wrapper.add(new WaitlistWrapper(waitListRec.Account__c, accName, waitListRec.Opportunity__c, oppName, waitListRec.Quote__c, waitListRec.Quote__r.Name, waitListRec.Quote_Line__c, waitListRec.Product__c, productName, waitListRec.Product__r.ProductCode, inventoryYr, waitlistQuantity, unit, waitListRec.Active__c, waitListRec.Wishlist_Product__c,waitListRec.Id,waitListRec.Product_Format__c,waitListRec.Other_Product_Format__c,'action:edit','Edit',waitListRec.Other_Wishlist_Product__c,waitListRec.Inactive_Reason_Code__c));
          }
          return wrapper;
      }
      
      @AuraEnabled(cacheable=true)
      public static List<WaitlistWrapper> getWishListRecordsFromQuoteLine(List<String> quoteIds) {
          List<WaitlistWrapper> wrapper = new List<WaitlistWrapper>();        
          Map<Id,SBQQ__QuoteLine__c> quoteLineMap = new Map<Id,SBQQ__QuoteLine__c>([SELECT Id,Name,SBQQ__Quote__c,SBQQ__Quote__r.SBQQ__OriginalQuote__c,SBQQ__Product__c,
                                                                                    SBQQ__Product__r.Name,SBQQ__ProductCode__c,Crop_Year__c,Available_Quantity__c,SBQQ__Quantity__c,
                                                                                    SBQQ__Quote__r.SBQQ__Account__c,SBQQ__Quote__r.SBQQ__Account__r.Name,SBQQ__Quote__r.SBQQ__Opportunity2__c,
                                                                                    SBQQ__Quote__r.SBQQ__Opportunity2__r.Name,Unit_of_measure__c,SBQQ__Quote__r.Name,SBQQ__Group__r.Unit_of_measure__c
                                                                                    FROM SBQQ__QuoteLine__c 
                                                                                    WHERE SBQQ__Quote__c IN: quoteIds AND SBQQ__Quote__r.SBQQ__Primary__c = true 
                                                                                    AND (Product_Category__c = 'Craft Brewing Contracted Hops' OR Product_Category__c = 'Craft Brewing Hops')]);
          Set<string> inventoryNameSet = new Set<String>();
          for(SBQQ__QuoteLine__c quoteLineRecord : quoteLineMap.values())
          {
              inventoryNameSet.add(quoteLineRecord.Crop_Year__c +' - '+ quoteLineRecord.SBQQ__ProductCode__c);            
          }
          if(!inventoryNameSet.isEmpty()){
              Map<Id,Inventory__c> inventoryMap = new Map<Id,Inventory__c>([SELECT Id,Name,Active__c,No_more_crop_available_with_Grower__c,Product__c,Product__r.ProductCode,Crop_Year__c,Available_Volume__c
                                                                            FROM Inventory__c WHERE Name IN:inventoryNameSet]);
              Map<String,Inventory__c> nameBasedInventoryMap = new Map<String,Inventory__c>();
              for(Inventory__c inventoryRecord : inventoryMap.values())
              {
                  nameBasedInventoryMap.put(inventoryRecord.name,inventoryRecord);
              }
              
              Map<String, Decimal> AggregateDetMap = new Map<String, Decimal>();
              for (AggregateResult ar : [SELECT Crop_Year__c,SBQQ__Product__r.ProductCode, SUM(SBQQ__Quantity__c) quoteLineAggregateQty from SBQQ__QuoteLine__c where SBQQ__Quote__c IN: quoteIds AND (Product_Category__c = 'Craft Brewing Contracted Hops' OR Product_Category__c = 'Craft Brewing Hops') GROUP BY SBQQ__Product__r.ProductCode,Crop_Year__c]) 
              {
                  String CropYearProductCode = ar.get('Crop_Year__c') +' - '+ar.get('ProductCode');
                  AggregateDetMap.put(CropYearProductCode, (Decimal)ar.get('quoteLineAggregateQty'));
              }
              
              List<String> AggregateDetAddedQLO = new List<String>();
              for(SBQQ__QuoteLine__c quoteLineObject : quoteLineMap.values())
              {
                  String inventoryName = quoteLineObject.Crop_Year__c +' - '+ quoteLineObject.SBQQ__ProductCode__c;
                  if(nameBasedInventoryMap.containsKey(inventoryName))
                  {
                      Decimal AggQty = AggregateDetMap.get(inventoryName);
                      if(AggQty > nameBasedInventoryMap.get(inventoryName).Available_Volume__c && nameBasedInventoryMap.get(inventoryName).Active__c == true)
                      {   
                       //   Decimal wlQty = AggQty - nameBasedInventoryMap.get(inventoryName).Available_Volume__c;
                          Boolean checkDupProductCropYear = AggregateDetAddedQLO.contains(inventoryName);
                          if(checkDupProductCropYear == false){
                          String accName = String.isNotBlank(quoteLineObject.SBQQ__Quote__r.SBQQ__Account__c) ? quoteLineObject.SBQQ__Quote__r.SBQQ__Account__r.Name : '';
                          String oppName = String.isNotBlank(quoteLineObject.SBQQ__Quote__r.SBQQ__Opportunity2__c) ? quoteLineObject.SBQQ__Quote__r.SBQQ__Opportunity2__r.Name : '';
                          String productName = String.isNotBlank(quoteLineObject.SBQQ__Product__c) ? quoteLineObject.SBQQ__Product__r.Name : '';
                          String inventoryYr = String.isNotBlank(quoteLineObject.Crop_Year__c) ? quoteLineObject.Crop_Year__c : '';
                          Decimal waitlistQuantity = AggQty-quoteLineObject.Available_Quantity__c != NULL ? AggQty-quoteLineObject.Available_Quantity__c : NULL;                       
                          String unit = String.isNotBlank(quoteLineObject.Unit_of_measure__c) ? quoteLineObject.SBQQ__Group__r.Unit_of_measure__c : '';
                          
                          wrapper.add(new WaitlistWrapper(quoteLineObject.SBQQ__Quote__r.SBQQ__Account__c, accName, quoteLineObject.SBQQ__Quote__r.SBQQ__Opportunity2__c, oppName, quoteLineObject.SBQQ__Quote__c, quoteLineObject.SBQQ__Quote__r.Name, quoteLineObject.Id, quoteLineObject.SBQQ__Product__c, productName, quoteLineObject.SBQQ__ProductCode__c, inventoryYr, waitlistQuantity, unit, true, '','','','','utility:add','New','',''));
                          AggregateDetAddedQLO.add(inventoryName);
                          }
                      }
                  }
              }
          }
          system.debug('wrapperInner::::'+ wrapper);
          return wrapper;
      }
      
      //@AuraEnabled
      public static List<selectOption> getWishListProduct()
      {     
          List<SelectOption> wishList = new List<SelectOption>();
          wishList.add(new SelectOption('', '--None--'));
          Schema.DescribeFieldResult field = Waitlist__c.Wishlist_Product__c.getDescribe();
          for (Schema.PicklistEntry listEntry : field.getPicklistValues()){
              wishList.add(new SelectOption(listEntry.getValue(), listEntry.getLabel()));            
          }
          return wishList;    
      }
      
      public class WaitlistWrapper {
          @AuraEnabled public Id accountId {get; set;}
          @AuraEnabled public String accountIdURL {get; set;}
          @AuraEnabled public String accountName {get;set;}
          @AuraEnabled public Id opportunityId {get; set;}
          @AuraEnabled public String opportunityIdURL {get; set;}
          @AuraEnabled public String opportunityName {get;set;}
          @AuraEnabled public Id quoteId {get; set;}
          @AuraEnabled public String quoteIdURL {get; set;}
          @AuraEnabled public String quoteName {get;set;}
          @AuraEnabled public Id quoteLineId {get; set;}
          @AuraEnabled public Id productId {get; set;}
          @AuraEnabled public String product {get;set;}
          @AuraEnabled public String productCode {get;set;}
          @AuraEnabled public String inventoryYear {get;set;}
          @AuraEnabled public Decimal waitlistQuantity {get;set;}
          @AuraEnabled public String unit {get;set;}
          @AuraEnabled public Boolean active {get;set;}
          @AuraEnabled public String waitlistProduct {get;set;}
          @AuraEnabled public String waitlistId {get;set;}
          @AuraEnabled public String productFormat {get;set;}
          @AuraEnabled public String otherProductFormat {get;set;}
          @AuraEnabled public String rowIconName {get;set;}
          @AuraEnabled public String rowIconAction {get;set;}
          @AuraEnabled public String hideIdColumn {get;set;}
          @AuraEnabled public String otherWishlistProduct {get;set;}
          @AuraEnabled public String inactiveReasonCode {get;set;}
          
          public WaitlistWrapper() {}
          
          public WaitlistWrapper(Id accId, String accName, Id oppId, String oppName, Id quoteId, String quoteNm, Id quoteLnId, Id prdId, String productName, String prodCode, String inventoryYr, Decimal waitlistQuan, String unitMeasure, Boolean activeFlag, String waitlistProd,String waitlistId,String productFormat,String otherProductFormat,String rowIconName,String rowIconAction,String otherWishlistProduct,String inactiveReasonCode) {
              this.accountId = accId;
              this.accountName = accName;
              this.accountIdURL = accId == null? '' : '/'+accId;
              this.opportunityId = oppId;
              this.opportunityName = oppName;
              this.opportunityIdURL =  oppId == null? '' : '/'+oppId;
              this.quoteId = quoteId;
              this.quoteName = quoteNm;
              this.quoteIdURL = quoteId == null? '' : '/'+quoteId;
              this.quoteLineId = quoteLnId;
              this.productId = prdId;
              this.product = productName;
              this.productCode = prodCode;
              this.inventoryYear = inventoryYr;
              this.waitlistQuantity = waitlistQuan;
              this.unit = unitMeasure;
              this.active = activeFlag;
              this.waitlistProduct = waitlistProd;
              this.waitlistId = waitlistId;
              this.productFormat = productFormat;
              this.otherProductFormat = otherProductFormat;
              this.rowIconName = rowIconName;
              this.rowIconAction = rowIconAction;
              this.hideIdColumn = 'hideIdColumn';
              this.otherWishlistProduct = otherWishlistProduct;
              this.inactiveReasonCode = inactiveReasonCode;
              
          }
      }
  }