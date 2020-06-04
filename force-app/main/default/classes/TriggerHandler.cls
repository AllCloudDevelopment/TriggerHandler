/**
 * Created by sebastianschepis on 4/24/20.
 */

public abstract class TriggerHandler {
    // exception is thrown on error  
    public class TriggerHandlerException extends Exception {
        
    }
    
    public static Map<String,Boolean> triggerStates = null;
    private static Map<String,Boolean> getTriggerStates() {
        if(triggerStates == null) {
            triggerStates =  new Map<String,Boolean>();
            for(AllCloud_Trigger_Setting__mdt s : [
                SELECT Value__c, DeveloperName, Enabled__c
                FROM AllCloud_Trigger_Setting__mdt]) {
                triggerStates.put(s.DeveloperName, s.Enabled__c == true);
            }
        }
        return triggerStates;
    }
    
    public TriggerHandler() {
    }
    
    // ***************************************************************************
    // Static methods all relate to TriggerHandler as the dispatcher of trigger calls
    
    // stores recursions
    private static Map<String,Set<Id>> recursions = new  Map<String,Set<Id>>();
    
    // used to control recursion execution, provides group and object-level control
    public static Boolean preventRecursion(String type, Id value) {
        Set<Id> ids = recursions.get(type);
        if(ids == null) {
            ids = new Set<Id>();
            recursions.put(type, ids);
        }
        Boolean isPresent = ids.contains(value);
        ids.add(value);
        return isPresent;
    }

    // // used to control recursion execution, provides type-level control
    public static Boolean preventRecursion(String type) {
        Boolean isPresent = false;
        if(type == null) {
            return false;
        }
        isPresent = recursions.keySet().contains(type);
        recursions.put(type, new Set<Id>());
        return isPresent;
    }
    
    // // used to control recursion execution, provides object-level control
    public static Boolean preventRecursion(Id value) {
        Set<Id> ids = recursions.get('__IDLIST__');
        if(ids == null) {
            ids = new Set<Id>();
            recursions.put('__IDLIST__', ids);
        }
        Boolean isPresent = ids.contains(value);
        ids.add(value);
        return isPresent;
    }
    
    public static void deleteAll(DescribeSObjectResult t) {
        delete Database.query('select id from ' + t.getName());
    }

    public static void undeleteAll(DescribeSObjectResult t) {
        undelete Database.query('select id from ' + t.getName() + ' where Isdeleted = TRUE ALL ROWS');
    }

    public void deleteAll() {
        deleteAll(this.sObjectType());
    }

    public void undeleteAll() {
        undeleteAll(this.sObjectType());
    }
    
    public static String guid() {
        String h = EncodingUtil.ConvertTohex(Crypto.GenerateAESKey(128));
        return h.SubString(0,8) 
            + '-' + h.SubString(8,12) 
            + '-' + h.SubString(12,16) 
            + '-' + h.SubString(16,20) 
            + '-' + h.substring(20);
    }
    
    public static Map<String,TriggerHandler> triggerHandlers 
        = new Map<String,TriggerHandler>();

    public static void reset() {
        triggerHandlers.clear();
        recursions.clear();
        disabledTypes.clear();
    }
    
    public static void setEnabled(String tagName, Boolean enabled) {
        if(tagName == null) return;
        getTriggerStates().put(tagName, enabled);
    }
    
    public static Boolean isEnabled(String tagName) {
        return tagName == null ? 
            true : 
            getTriggerStates().get(tagName) == null?
                true :
                getTriggerStates().get(tagName);
    }
    
    private static Set<DescribeSObjectResult> disabledTypes = new Set<DescribeSObjectResult>();
    public static void setEnabled(DescribeSObjectResult typeName, Boolean enabled) {
        if(!enabled) {
            disabledTypes.add(typeName);
        } else {
            disabledTypes.remove(typeName);
        }
    }
    
    public static Boolean isEnabled(DescribeSObjectResult typeName) {
        return !disabledTypes.contains(typeName);
    }
    
    public static TriggerHandler register(
        String handlerClass,
        Map<Id,SObject> oldMap,
        Map<Id,SObject> newMap,
        Boolean isBefore,
        Boolean isAfter,
        Boolean isInsert,
        Boolean isUpdate,
        Boolean isDelete,
        Boolean isUndelete) {
        
        // make sure we have a type and that the type is valid
        Type t = Type.forName(handlerClass);
        if (t == null) {
            throw new TriggerHandlerException('trigger handler was not found');
        }
        
        // create and configure the trigger handler, add it to the list
        // with a new GUID, and then execute the handler code
        TriggerHandler handler = (TriggerHandler) t.newInstance();
        
        String handlerGuid = guid();
        handler.configure(
            handlerGuid,
            oldMap,
            newMap,
            isBefore,
            isAfter,
            isInsert,
            isUpdate,
            isDelete,
            isUndelete);
        triggerHandlers.put(handlerGuid, handler);
        
        return handler;
    }
    
    public static List<TriggerHandler> handle(DescribeSObjectResult objType) {
        List<TriggerHandler> ret = new List<TriggerHandler>();
        for(TriggerHandler handler : triggerHandlers.values()) {
            if (handler.isEnabled() && handler.sObjectType() == objType) {
                ret.add(handler.handle());
            }
        }
        return ret;
    }

    // ***************************************************************************
    // Instance methods all relate to TriggerHandler as the processor of trigger logic

    // guid of running handler
    public String guid;
    
    // a string tag identifying the trigger handler. used to enable / disable triggers
    public String tag;
    
    // keys and objects
    public List<Id> keyList;
    public List<SObject> oldList;
    public List<SObject> newList;
    public Map<Id,SObject> oldMap;
    public Map<Id,SObject> newMap;

    // Trigger context 
    Boolean isBefore;
    Boolean isAfter;
    Boolean isInsert;
    Boolean isUpdate;
    Boolean isDelete;
    Boolean isUndelete;

    public Boolean isEnabled() {
        return isEnabled(this.tag)
            || isEnabled(this.guid)
            || isEnabled(this.sObjectType());
    }
    
    // configurator
    public TriggerHandler configure (
        String guid,
        Map<Id,SObject> oldMap,
        Map<Id,SObject> newMap,
        Boolean isBefore,
        Boolean isAfter,
        Boolean isInsert,
        Boolean isUpdate,
        Boolean isDelete,
        Boolean isUndelete
    ) {
        this.guid = guid;
        
        this.tag = this.sObjectType().getLabel();

        // init context variables
        this.isBefore = isBefore;
        this.isAfter = isAfter;
        this.isInsert = isInsert;
        this.isUpdate = isUpdate;
        this.isDelete = isDelete;
        this.isUndelete = isUndelete;

        // set up old and new context variables
        if(oldMap != null) {
            this.oldMap = new Map<Id,SObject>(oldMap);
            this.oldList = new List<SObject>(oldMap.values());
        }
        if(newMap != null) {
            this.newMap = new Map<Id,SObject>(newMap);
            this.newList = new List<SObject>(newMap.values());
            this.keyList = new List<Id>(newMap.keySet());
        }
        return this;
    }

    // return the sObject type
    public virtual DescribeSObjectResult sObjectType() {
        return null;
    }
    
    private String getTag(String s) {
        return sObjectType().name + '.' + s;
    }
    
    public virtual void onBeforeInsert() {}
    public virtual void onBeforeUpdate() {}
    public virtual void onBeforeDelete() {}
    public virtual void onBeforeUndelete() {}

    public virtual void onAfterInsert() {}
    public virtual void onAfterUpdate() {}
    public virtual void onAfterDelete() {}
    public virtual void onAfterUndelete() {}

    // handle the trigger
    public TriggerHandler handle() {
        if(this.isBefore && isEnabled(getTag('before'))) {
            if(this.isInsert && isEnabled(getTag('insert')) && isEnabled(getTag('onBeforeInsert'))) onBeforeInsert();
            if(this.isUpdate && isEnabled(getTag('update')) && isEnabled(getTag('onBeforeUpdate'))) onBeforeUpdate();
            if(this.isDelete && isEnabled(getTag('delete')) && isEnabled(getTag('onBeforeDelete'))) onBeforeDelete();
            if(this.isUndelete && isEnabled(getTag('undelete')) && isEnabled(getTag('onBeforeUndelete'))) onBeforeUndelete();
        }
        if(this.isAfter && isEnabled(getTag('after'))) {
            if(this.isInsert && isEnabled(getTag('insert')) && isEnabled(getTag('onAfterInsert'))) onAfterInsert();
            if(this.isUpdate && isEnabled(getTag('update')) && isEnabled(getTag('onAfterUpdate'))) onAfterUpdate();
            if(this.isDelete && isEnabled(getTag('delete')) && isEnabled(getTag('onAfterDelete'))) onAfterDelete();
            if(this.isUndelete && isEnabled(getTag('undelete'))&& isEnabled(getTag('onAfterUndelete'))) onAfterUndelete();
        }
        return this;
    }
}