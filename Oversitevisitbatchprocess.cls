/*************************************************************
* Class Name         : Oversitevisitbatchprocess
* Purpose            : To calculate the Over Site visit and generate the Opporunity record accordingly. 
* Created By         : Lightful - Sampath
* Created Date       : 29th Dec 2018
* Last Modified date : 29th Dec 2018
* **********************************************************/
global class Oversitevisitbatchprocess implements 
    Database.Batchable<sObject>, Database.Stateful {
    
    // instance member to retain state across transactions
    global Integer recordsProcessed = 0;
    global Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator(
            'SELECT ID, Name,Site__c, BillingCity, OSVOPPID__c,BillingState,BillingPostalCode, (SELECT ID, Name,MASVH__c,MASVO__c,MActSVO__c,MActSVH__c,Site__c,Site_ID__c,MailingStreet, MailingCity, ' +
            'MailingState, MailingPostalCode FROM Contacts) FROM Account ' + 
            'Where Relationship__c = \'Customers\' OR Relationship__c = \'Former Customers\''
        );
    }
    global void execute(Database.BatchableContext bc, List<Account> scope){
        List<OpportunityLineItem> listOLI = new list<OpportunityLineItem>();
        List<PricebookEntry> listPBE = new List<PricebookEntry>();
        List<Opportunity> deleteoppids = new List<Opportunity>();
        Id productid = [select id,name from Product2 where name=:label.Product_Name and isActive=TRUE LIMIT 1].id;
        if(productid!=null){
            listPBE= [select id,name,UnitPrice from PricebookEntry where Product2Id=:productid];
        }
        List<opportunity> listopp = new List<Opportunity>();
        for (Account acc : scope) {
            
            for (Contact con : acc.contacts) {
                Integer homeoversitevisit = 0;
                Integer otehroversitevisit = 0;
                Integer totaloversitevisit = 0;
                system.debug('&&&&ActH'+(Integer)con.MActSVH__c);
                system.debug('&&&&AH'+(Integer)con.MASVH__c);
                system.debug('&&&&ActO'+(Integer)con.MActSVO__c);
                system.debug('&&&&AO'+(Integer)con.MASVO__c);
                if(con.MActSVH__c > con.MASVH__c){
                    homeoversitevisit = (Integer)con.MActSVH__c - (Integer)con.MASVH__c;
                }
                if(con.MActSVH__c > con.MASVH__c){
                    otehroversitevisit = (Integer)con.MActSVO__c - (Integer)con.MASVO__c;
                }
                system.debug('***hsv'+homeoversitevisit);
                system.debug('***osv'+otehroversitevisit);
                totaloversitevisit = homeoversitevisit + otehroversitevisit;
                if(totaloversitevisit > 0){
                    OpportunityLineItem OLI = new OpportunityLineItem();
                    OLI.OpportunityId = acc.OSVOPPID__c; //Opportunity Id has to be assigned
                    OLI.PricebookEntryId = listPBE[0].Id; //PriceBookEntry Id for that Product should be assigned.
                    OLI.Quantity = totaloversitevisit;
                    OLI.UnitPrice = listPBE[0].UnitPrice;
                    OLI.OSVCon__c = con.id;
                    listOLI.add(OLI);
                }
                else{
                    if(acc.OSVOPPID__c!=null){
                        Opportunity delopp= new Opportunity();
                        delopp.id = acc.OSVOPPID__c;
                        deleteoppids.add(delopp);
                    }
                    
                }
                recordsProcessed = recordsProcessed + 1;
            }
        }
        if(listOLI.size() > 0){
            insert listOLI; 
        }
        if(deleteoppids.size()>0){
            Set<Opportunity> setopp = new Set<Opportunity>();
            List<Opportunity> result = new List<Opportunity>();
            setopp.addAll(deleteoppids);
            result.addAll(setopp);
            delete result;
        }
                   
    }    
    global void finish(Database.BatchableContext bc){
        System.debug(recordsProcessed + ' records processed.!');
        AsyncApexJob job = [SELECT Id, Status, NumberOfErrors, 
            JobItemsProcessed,
            TotalJobItems, CreatedBy.Email
            FROM AsyncApexJob
            WHERE Id = :bc.getJobId()];
        // call some utility to send email
        //EmailUtils.sendMessage(a, recordsProcessed);
    }    
}