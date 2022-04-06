/*******************************************************************************************
* @author           Demandblue
* @version          1.0 
* @Status           Development Completed
* @description      This class is used to validate status of Inventory Reserve. 
*********************************************************************************************
Version    	Date        	Team    	Comments
*********************************************************************************************
* 1    		20 Mar 2021    	Pradeep    	Initial Development 
*********************************************************************************************/
public class StatusController {
    public static Boolean recursion = true;
    
    
    public static void stageValidation(Map<Id,Inventory_Reserve__c> InventoryNewMap,Map<Id,Inventory_Reserve__c> InventoryOldMap)
    {
        
        recursion = false;
        //Get dependentvalues from the Status Dependent field
        Map<String,List<String>> dependentPicklistValues = new Map<String,List<String>>(InventoryReserveController.getDependentPicklistValues(Inventory_Reserve__c.Status_dependent__c));
        
        for(Inventory_Reserve__c Inventoryreserveobject : InventoryNewMap.values())
        {
            
                if(dependentPicklistValues.containsKey(InventoryOldMap.get(Inventoryreserveobject.Id).Status__c) && !dependentPicklistValues.get(InventoryOldMap.get(Inventoryreserveobject.Id).Status__c).contains(Inventoryreserveobject.Status__c) && Inventoryreserveobject.Status__c !=  InventoryOldMap.get(Inventoryreserveobject.Id).Status__c)
                {
                    // Dynamic Error message which has to be shown during error conditions
                    Inventoryreserveobject.addError('You cannot go to "'+Inventoryreserveobject.Status__c+'" status."');
                }
            
        }
        
    }
    
    
    
    
}