/**
 * Created by sebastianschepis on 4/24/20.
 */

public class TriggerHandlerTestHandler extends TriggerHandler {
    
    public static Integer callCount = 0;
    public static String lastCalled = '';
    
    public static void resetTest() {
        callCount = 0;
        lastCalled = '';
    }
    
    public override DescribeSObjectResult sObjectType() {
        return Lead.getSObjectType().getDescribe();
    }

    public override void onAfterInsert() {
        callCount++;
        lastCalled = 'onAfterInsert';
    }

    public override void onAfterUpdate() {
        callCount++;
        lastCalled = 'onAfterUpdate';
    }

    public override void onAfterDelete() {
        callCount++;
        lastCalled = 'onAfterDelete';
    }
    
    public override void onAfterUndelete() {
        callCount++;
        lastCalled = 'onAfterUndelete';
    }

    public override void onBeforeInsert() {
        callCount++;
        lastCalled = 'onBeforeInsert';
    }
}