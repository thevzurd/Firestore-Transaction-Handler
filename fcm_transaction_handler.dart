import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:meta/meta.dart' show required;
//  This code is a solution to errors with cloud_firestore package for Flutter for the following errors
// 'PlatformException(Error performing Transaction#get, Transaction has already completed., null)'
// And 'DoTransaction failed: Document version changed between two reads.'
// From my experience, I realized that the issue occurs when I try to update a record which was only just created. 
// For some reason the tx.get() (see the example for runTransaction in https://pub.dev/packages/cloud_firestore) is unable to get the 
// record that was just created and the update operation fails. I found that if we wait for a bit and try again, 
// we will be able to get the record and update it. To make things easy, I create a function that does the update and run transaction for you.
// Here is an example : 
//     await fcmTransactionHandler(
//      postRef: postRef, //  This is your DocumentReference that you want to update
//      key: 'myfield', // This is the field that you want to update
//      validationFunction: updateMyField, // This is a function that allows you to check some condition in the record you 'get' before updating
//   );
// validationFunction takes a dynamic value (value of the field you want to update) as input and gives the {} value that you will update
// in the record
// For example, if I want to update a field 'myfield' if it is say 'true', then I will create a function 'updateMyField' as follows
// Map<String, dynamic> updateMyField({dynamic value}) {
//    return  value ? <String, dynamic>{'myfield': true} : <String, dynamic>{'myfield': value};
//  }
// Then this function is passed to validationFunction.
// Why is it designed like this ? As you have seen, we are trying to get the record after a while and then update it. What if the record
// has been updated by someone else in between ? In that case, we have to validate the data we get when the record is available for us,
// to prevent any incorrect updates

Future<bool> fcmTransactionHandler({
  @required DocumentReference postRef,
  @required String key,
  @required
      Map<String, dynamic> Function({@required dynamic value})
          validationFunction,
}) async {
  int count = 1;
  bool transactionSuccessfull = false;
  await Future.doWhile(() async {
    //Executes until it returns false
    if (count > 10) {
      // Handle your error
      return false;
    }
    transactionSuccessfull = await _runTransaction(
        postRef: postRef, key: key, validationFunction: validationFunction);
    //print(
    //    '${DateTime.now().toUtc()} : ${postRef.documentID} t $transactionSuccessfull $count');
    if (transactionSuccessfull) {
      return false;
    } else {
      return Future<bool>.delayed(Duration(seconds: count * 1), () {
        print(
            '${DateTime.now().toUtc()} : ${postRef.documentID} waited $count seconds');
        count = count + 1;
        return true;
      });
    }
  }).then((dynamic onValue) {}).catchError((dynamic onError) {
  // Handle your error
    return false;
  });
  return true;
}

Future<bool> _runTransaction({
  @required DocumentReference postRef,
  @required String key,
  @required
      Map<String, dynamic> Function({@required dynamic value})
          validationFunction,
}) async {
  bool transactionSuccessfull = false;
  await Firestore.instance.runTransaction((Transaction tx) async {
    final DocumentSnapshot postSnapshot = await tx.get(postRef);
    if (postSnapshot.exists) {
      //print(
      //    '${DateTime.now().toUtc()} : ${postRef.documentID} transaction exists ');
      final Map<String, dynamic> data =
          validationFunction(value: postSnapshot.data[key]);
      //print('data $data');
      await tx.update(postRef, data).then((void onValue) {
        //  print(
        //      '${DateTime.now().toUtc()} : ${postRef.documentID} transaction successfull 1');
        transactionSuccessfull = true;
      }).catchError((dynamic onError) {
  // Handle your error
        transactionSuccessfull = false;
      });
    } else {
      //print(
      //    '${DateTime.now().toUtc()} : ${postRef.documentID} !transaction exists');
      transactionSuccessfull = false;
    }
  }).catchError((dynamic onError) {
  // Handle your error
    transactionSuccessfull = false;
  });
  return transactionSuccessfull;
}
