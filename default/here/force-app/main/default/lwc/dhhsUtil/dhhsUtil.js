
/**
 * Created by hans on 11/10/20.
 */

import { ShowToastEvent } from 'lightning/platformShowToastEvent'
export const showToast = (variant, message, messageData, mode = 'dismissable') => (context) => {
    const evt = new ShowToastEvent({
        message,
        variant,
        messageData,
        mode,
    });
    context.dispatchEvent(evt);
}

/**
 * Handle errors thrown from standard apex exceptions,
 * note: update the method if needed to support different formats
 * @param error
 * @param mode
 * @returns {function(...[*]=)}
 */
export const handleError = (error, mode = 'dismissable') => (context) => {
    console.log('Error Handler ',error.body.pageErrors);
    //console.log('Error Handler ',error.body.fieldErrors);
    let messages = 'Unknown error';
    if (error.body.output && Array.isArray(error.body.output.errors) && error.body.output.errors.length > 0) {
        messages = error.body.output.errors.map(e => e.message).join(', ');
    } else if (error.body.output && isObject(error.body.output.fieldErrors)) {
        console.log('Error Handler error.body.output.fieldErrors ',error.body.output.fieldErrors);
        //messages = error.body.output.fieldErrors.PracticeCase__c.map((e, i) => e[i].message).join(', ');
        messages = Object.keys(error.body.output.fieldErrors).map(k => error.body.output.fieldErrors[k]).map((e, i) => e[i].message).join(', ');
        console.log('messages ',messages);
    } /*else if(error.body.pageErrors) {
        messages = Object.keys(error.body.pageErrors);//.map(k => error.body.pageErrors[k]).map((e, i) => e[i].message).join(', ');
    }*/ else if(typeof error.body.message === 'string') {
        messages = error.body.message;
    } else if (typeof error.message === 'string') {
        messages = error.message;
    }
    showToast('error',  messages, mode)(context)
}
/*  implementation of load get

    Gets the value at path of object. If the resolved value is undefined,
    the defaultValue is returned in its place.
*/
export const get = (object, path, defaultVal) => {
    path = Array.isArray(path) ? path : path.split('.');
    if(object === undefined) return defaultVal;
    object = object[path[0]];
    if (object && path.length > 1) {
        return get(object, path.slice(1));
    }
    return object === undefined ? defaultVal : object;
}

export const empty = (object) => {
    for(const key in object) {
        if(object.hasOwnProperty(key))
            return false;
    }
    return true;
}

/**
 * is the passed parameter an object?
 * @param obj
 * @returns {boolean|boolean}
 */
export const isObject = (obj) => {
    return !!obj && (typeof obj === 'object' || typeof obj === 'function')
}

