/**
 * Created by sebastianschepis on 4/24/20.
 */

@IsTest
private class TriggerHandlerTest {
    @IsTest
    static void test() {
        Test.startTest();
        
        // register the trigger handler and then handle it
        TriggerHandler.register(
            'TriggerHandlerTestHandler',
            new Map<Id,Account>(),
            new Map<Id,Account>(),
            False,
            True,
            True,
            False,
            False,
            False
        );
        TriggerHandlerTestHandler th 
            = (TriggerHandlerTestHandler) 
                TriggerHandler.handle(Lead.getSObjectType().getDescribe())[0];

        System.assertEquals(TriggerHandlerTestHandler.lastCalled, 'onAfterInsert');
        
        TriggerHandler.reset();
        TriggerHandlerTestHandler.resetTest();
        
        // register the trigger handler and then handle it
        TriggerHandler.register(
            'TriggerHandlerTestHandler',
            new Map<Id,Lead>(),
            new Map<Id,Lead>(),
            False,
            True,
            False,
            True,
            False,
            False
        );
        th = (TriggerHandlerTestHandler)
               TriggerHandler.handle(Lead.getSObjectType().getDescribe())[0];
        
        System.assertEquals(TriggerHandlerTestHandler.lastCalled, 'onAfterUpdate');

        TriggerHandler.reset();
        TriggerHandlerTestHandler.resetTest();
        
        // register the trigger handler and then handle it
        TriggerHandler.register(
            'TriggerHandlerTestHandler',
            new Map<Id,Lead>(),
            new Map<Id,Lead>(),
            False,
            True,
            False,
            False,
            True,
            False
        );
        TriggerHandler.setEnabled('Lead.onAfterDelete', false);
        
        th = (TriggerHandlerTestHandler)
            TriggerHandler.handle(Lead.getSObjectType().getDescribe())[0];
        
        TriggerHandler.triggerStates.remove('Lead.onAfterDelete');

        TriggerHandler.reset();
        TriggerHandlerTestHandler.resetTest();

        // register the trigger handler and then handle it
        TriggerHandler.register(
            'TriggerHandlerTestHandler',
            new Map<Id,Lead>(),
            new Map<Id,Lead>(),
            False,
            True,
            False,
            False,
            True,
            False
        );
        TriggerHandler.setEnabled('TriggerHandlerTestHandler.onAfterDelete', true);

        th = (TriggerHandlerTestHandler)
            TriggerHandler.handle(Lead.getSObjectType().getDescribe())[0];

        System.assertEquals(TriggerHandlerTestHandler.lastCalled, 'onAfterDelete');


        // register the trigger handler and then handle it
        TriggerHandler.register(
            'TriggerHandlerTestHandler',
            new Map<Id,Lead>(),
            new Map<Id,Lead>(),
            True,
            False,
            True,
            False,
            False,
            False
        );
        TriggerHandler.setEnabled('TriggerHandlerTestHandler.onBeforeInsert', true);

        th = (TriggerHandlerTestHandler)
            TriggerHandler.handle(Lead.getSObjectType().getDescribe())[0];

        System.assertEquals(TriggerHandlerTestHandler.lastCalled, 'onBeforeInsert');
        TriggerHandler.reset();
        TriggerHandlerTestHandler.reset();
        
        System.assertEquals(TriggerHandler.preventRecursion((Id)('001e000001WJYWTAA5')), False);
        System.assertEquals(TriggerHandler.preventRecursion((Id)('001e000001WJYWTAA5')), True);

        TriggerHandler.reset();
        TriggerHandlerTestHandler.reset();
        
        System.assertEquals(TriggerHandler.preventRecursion('ZZZ'), False);
        System.assertEquals(TriggerHandler.preventRecursion('ZZZ'), True);

        TriggerHandler.reset();
        TriggerHandlerTestHandler.reset();

        System.assertEquals(TriggerHandler.preventRecursion('TYPE',(Id)('001e000001WJYWTAA5')), False);
        System.assertEquals(TriggerHandler.preventRecursion('TYPE',(Id)('001e000001WJYWTAA5')), True);
        
        TestDataFactory.createSObject('Lead');
        TriggerHandler.deleteAll(Lead.getSObjectType().getDescribe());
        System.assertEquals([select id from Lead].size(), 0);
        TriggerHandler.undeleteAll(Lead.getSObjectType().getDescribe());
        System.assertEquals([select id from Lead].size(), 1);
        
        TriggerHandler.setEnabled(Lead.getSObjectType().getDescribe(), false);
        System.assertEquals(TriggerHandler.isEnabled(Lead.getSObjectType().getDescribe()), false);
        TriggerHandler.setEnabled(Lead.getSObjectType().getDescribe(), true);
        System.assertEquals(TriggerHandler.isEnabled(Lead.getSObjectType().getDescribe()), true);
        
        
        Test.stopTest();
    }
}