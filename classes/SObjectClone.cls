/**
* @Description     :   This class is used to clone the sObject
**/
public with sharing class SObjectClone 
{
    /**
    * @Description     :   This method is used to clone the sObject with the related list
    **/
    public static String cloneWithRelatedRecords(Id recordId, Map<String, String> relatedListWithWhereClause)
    {
        String recIdPrefix = String.valueOf(recordId).substring(0,3);
        String recIdObjectName = '';
        String newRecordId = '';
        Map<String, Schema.SObjectType> gd = Schema.getGlobalDescribe(); 
        Schema.DescribeSObjectResult parentObjectDesc;
        
        for(String sObj : gd.keySet())
        {
            Schema.DescribeSObjectResult r = gd.get(sObj).getDescribe();
            String prefix = r.getKeyPrefix();
            
            if(prefix != null && prefix.equals(recIdPrefix))
            {
                recIdObjectName = r.getName();
                parentObjectDesc = r;
                break;
            }
        }

        System.debug('@@@ '+ recIdObjectName);

        if(String.isNotBlank(recIdObjectName))
        {
            String parentObjectQueryString = 'SELECT Id FROM '+ recIdObjectName + ' WHERE Id = \'' + recordId + '\'';

            sObject parentClonedObject = cloneObjects(new List<sObject>{Database.query(parentObjectQueryString)}).get(0);
            insert parentClonedObject;
            newRecordId = parentClonedObject.Id;

            List<Schema.ChildRelationship> childRelationships = parentObjectDesc.getChildRelationships();
            List<relatedObjectsWrap> relatedObjectsWrapList = new List<relatedObjectsWrap>();
            Integer index = 0;

            for (Schema.ChildRelationship childRelationship : childRelationships)
            {
                if(!relatedListWithWhereClause.isEmpty() && relatedListWithWhereClause.containsKey(childRelationship.getRelationshipName()))
                {
                    System.debug('@@@ '+ childRelationship);
                    System.debug('@@@ '+ childRelationship.getChildSObject());

                    Schema.SObjectType childObjectType = childRelationship.getChildSObject();
                    Schema.SObjectField childObjectField = childRelationship.getField();
                    String childObjFieldName = childObjectField.getDescribe().getName();

                    String whereClause = relatedListWithWhereClause.get(childRelationship.getRelationshipName());
                    String relatedChildSObjectsquery = 'SELECT ID FROM ' + childObjectType.getDescribe().getName()
                        + ' WHERE '+ childObjFieldName + ' = \'' + recordId + '\'';
                    
                    if (whereClause != null && whereClause != '')
                    {
                        relatedChildSObjectsquery += ' AND ' + whereClause;
                    }
                    
                    List<sObject> relatedChildSObjectsList = new List<sObject>();
                    
                    System.debug('###### ' + relatedChildSObjectsquery);

                    for (SObject childObject : Database.query(relatedChildSObjectsquery))
                    {
                        relatedChildSObjectsList.add(childObject);
                    }

                    if (!relatedChildSObjectsList.isEmpty())
                    {
                        relatedObjectsWrapList.add(new relatedObjectsWrap(relatedChildSObjectsList, childObjFieldName));
                    }
                }
            }

            List<sObject> clonedObjects = new List<sObject>();
            
            for (relatedObjectsWrap relatedObject : relatedObjectsWrapList)
            {                        
                if (!relatedObject.sObjectLists.isEmpty())
                {
                    clonedObjects = cloneObjects(relatedObject.sObjectLists);
                    
                    for (sObject clone : clonedObjects)
                    {
                        clone.put(relatedObject.relatedFieldName, parentClonedObject.Id);  
                    }
                    
                    insert clonedObjects;
                }
            }
        }
        else 
        {
            System.debug('recIdObjectName is blank');
        }

        return newRecordId;
    }

    /**
    * @Description     :   This method is used to clone the sObject
    **/

    public static List<sObject> cloneObjects(List<sObject> sObjects)
    {
        Schema.SObjectType objectType = sObjects.get(0).getSObjectType();
        
        List<Id> sObjectIds = new List<Id>();
        List<String> sObjectFields = new List<String>();
        List<sObject> clonedSObjects = new List<sObject>();
        
        if(objectType != null)
        {
            for (Schema.SObjectField objField : objectType.getDescribe().fields.getMap().values())
            { 
                Schema.DescribeFieldResult fieldDesc = objField.getDescribe();

                sObjectFields.add(fieldDesc.Name);
            }
        }
        

        if (sObjects != null || sObjects.isEmpty() || sObjectFields.isEmpty())
        {
            for (sObject objectInstance: sObjects)
            {
                sObjectIds.add(objectInstance.Id);
            }

            String allSObjectFieldsQuery = 'SELECT ' + sObjectFields.get(0); 
            
            for (Integer i=1 ; i < sObjectFields.size() ; i++)
            {
                allSObjectFieldsQuery += ', ' + sObjectFields.get(i);
            }
            
            allSObjectFieldsQuery += ' FROM ' + objectType.getDescribe().getName() + ' WHERE ID IN (\'' + sObjectIds.get(0) + '\'';
            
            for (Integer i=1 ; i < sObjectIds.size() ; i++)
            {
                allSObjectFieldsQuery += ', \'' + sObjectIds.get(i) + '\'';
            }
            
            allSObjectFieldsQuery += ')';
            
            system.debug('allSObjectFieldsQuery: ' + allSObjectFieldsQuery);
            
            try
            {   
                for (SObject sObjectFromDatabase: Database.query(allSObjectFieldsQuery))
                {
                    clonedSObjects.add(sObjectFromDatabase.clone(false,true));  
                } 
            }
            catch (exception e)
            {
                System.debug('exception '+ e.getMessage());
            }
        }
        return clonedSObjects;
    }

    public class relatedObjectsWrap
    {
        public List<sObject> sObjectLists;
        public String relatedFieldName;
        
        public relatedObjectsWrap(List<sObject> sObjectLists, String relatedFieldName) 
        {
            this.sObjectLists      = sObjectLists;
            this.relatedFieldName  = relatedFieldName;
        }   
    }
}