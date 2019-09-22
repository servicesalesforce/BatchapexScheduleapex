/*************************************************************
* Class Name         : Oversitevisitbatchprocessschedule
* Purpose            : To schedle the Oversitevisitbatchprocess batch class. 
* Created By         : Lightful - Sampath
* Created Date       : 28th Oct 2018
* Last Modified date : 28th Nov 2018
* **********************************************************/
global class Oversitevisitbatchprocessschedule Implements Schedulable {
     global void execute(SchedulableContext sc) {
        Oversitevisitbatchprocess obj = new Oversitevisitbatchprocess();
        Database.executeBatch(obj);
    }

}