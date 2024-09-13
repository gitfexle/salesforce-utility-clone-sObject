/**
*  Description     :   This class is used to test the WorkOrderHelper class
**/
@isTest(seeAllData = false)
public class SObjectCloneTest 
{
    @isTest
    public static void cloneWithRelatedRecordsTest()
    {
        lhcDataFactory.newGCSetting();
        Account account = lhcDataFactory.newAccount('Test');
        insert account;
        Schema.Location location = lhcDataFactory.newLocation(account.Id);
        insert location;
        Asset installedProduct = lhcDataFactory.newGensetIP(location.Id);
        insert installedProduct;
        WorkOrder workOrder = lhcDataFactory.newWorkOrder(account.Id, location.Id);
        insert workOrder;
        Skill__c skill= new Skill__c(name = 'Test Skill', Abbreviated_Skill_Name__c = 'TSK', Skill_Type__c = Constants.SKILL_SKILL_TYPE_CORRECTION); 
        insert skill;

        Repair_Line__c repairLine1 = new Repair_Line__c(Asset__c = installedProduct.Id, ProbCauseCorr1__c = skill.Id, WorkOrder__c = workOrder.Id );
        Repair_Line__c repairLine2 = new Repair_Line__c(Asset__c = installedProduct.Id, ProbCauseCorr1__c = skill.Id, WorkOrder__c = workOrder.Id );
        List<Repair_Line__c> listOfRepairLineToInsert = new List<Repair_Line__c>{repairLine1, repairLine2};
        
        insert listOfRepairLineToInsert;

        Test.startTest();
            
            Map<String, String> relatedListData = new  Map<String, String>();
            relatedListData.put('Repair_Lines1__r','');
            SObjectClone.cloneWithRelatedRecords(workOrder.Id, relatedListData);

            List<WorkOrder> workOrderList = [SELECT Id FROM WorkOrder];
            Assert.areEqual(2, workOrderList.size(), 'Work order size should be 2');

            List<Repair_Line__c> repairLineList = [SELECT Id FROM Repair_Line__c];
            Assert.areEqual(4, repairLineList.size(), 'Repair line size should be 4');

        Test.stopTest();
    }
}