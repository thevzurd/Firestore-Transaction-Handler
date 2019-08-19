# Firestore-Transaction-Handler
This is a subroutine to help handle the failing transaction issue when using `runTransaction` function in `cloud_firestore` pub for `Flutter`

# The Problem
This code is a solution to errors with cloud_firestore package for Flutter for the following errors 
1.  `PlatformException(Error performing Transaction#get, Transaction has already completed., null)`
2.  `DoTransaction failed: Document version changed between two reads.`

From my experience, I realized that the issue occurs when I try to update a record which was only just created.
For some reason the `tx.get()` (see the example for `runTransaction` in https://pub.dev/packages/cloud_firestore) is unable to get the record that was just created and the update operation fails. 
I found that if we wait for a bit and try again, we will be able to get the record and update it. 
To make things easy, I have created a function that does the update and run transaction for you.

# The Solution
Here is an example : 
```
     await fcmTransactionHandler(
      postRef: postRef, //  This is your DocumentReference that you want to update
      key: 'myfield', // This is the field that you want to update
      validationFunction: updateMyField, // This is a function that allows you to check 
      // some condition in the record you 'get' before updating
 );
 ```
`validationFunction` takes a dynamic value (value of the field you want to update) as input and gives the `{}` value that you will update in the record.
For example, if I want to update a field `myfield` if it is say `true`, then I will create a function `updateMyField` as follows
```
Map<String, dynamic> updateMyField({dynamic value}) {
    return  value ? <String, dynamic>{'myfield': true} : <String, dynamic>{'myfield': value};
  }
```
Then this function is passed to `validationFunction`.
Why is it designed like this ? 
As you have seen, we are trying to get the record after a while and then update it. What if the record has been updated by someone else in between ?
In that case, we have to validate the data we get when the record is available for us, to prevent any incorrect updates.
`validationFunction` helps us do that.
