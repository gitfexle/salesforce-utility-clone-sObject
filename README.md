# SObjectClone Class

## Overview

The `SObjectClone` class provides functionality to clone a Salesforce record along with its related records based on specified criteria. This includes cloning the record itself and any associated records from related lists that meet the provided where clause criteria.

## Features

- **Clone a Record**: Clone a specified Salesforce record using its Record Id.
- **Clone Related Records**: Clone related records from specified related lists with criteria-based filtering.
- **Return Cloned Record Id**: Returns the Id of the newly cloned record.
- **Error Handling**: Includes basic error handling for DML and query operations.

## Usage

### Method: `cloneWithRelatedRecords`

This method performs the cloning operation, including related records.

#### Syntax

```apex
SObjectClone.cloneWithRelatedRecords(Id recordId, Map<String, String> relatedListWithWhereClause)
```

#### Parameters

- **recordId**: `Id` - The Id of the record to be cloned.
- **relatedListWithWhereClause**: `Map<String, String>` - A map where keys are the names of related lists and values are where clause criteria for cloning related records.

#### Example

To clone a Work Order with Id `0WO5b000000gIRcGAM` and its related Work Order Line Items and Repair Lines, use:

```apex
String clonedRecordId = SObjectClone.cloneWithRelatedRecords(
    '0WO5b000000gIRcGAM',
    new Map<String, String>{
        'WorkOrderLineItems' => 'Line_Status__c=\'Open\' AND Is_Billable__c=true',
        'Repair_Lines1__r' => 'Work_Order_Status__c=\'Complete\' AND Engine_Hour_Meter__c<=0'
    }
);
```

#### Returns

- **String** - The Id of the newly cloned record.

#### Exceptions

- **DmlException** - Thrown if there is an issue with DML operations.
- **QueryException** - Thrown if there is an issue with querying related records.
- **IllegalArgumentException** - Thrown if invalid parameters are provided.

## Notes

- The class uses the `cloneObjects` helper method to handle the actual cloning of sObjects.
- Make sure that the where clauses provided in the `relatedListWithWhereClause` map are valid SOQL where conditions.
- The `cloneObjects` method handles cloning of fields for the given sObjects.
