import 'dart:math';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fast_contacts/fast_contacts.dart';
import 'package:flutter/material.dart';
import 'package:hitchify/core/app_export.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geodesy/geodesy.dart';

class AddFriends extends StatefulWidget {
  const AddFriends({super.key});

  @override
  State<AddFriends> createState() => _AddFriendsState();
}

class _AddFriendsState extends State<AddFriends> {
  void sendRequest(String phoneNumber) async {
    // Get the last 5 digits of the phone number
    String last5Digits = phoneNumber.replaceAll(RegExp(r'[^0-9]'), '');
    last5Digits = last5Digits.length >= 5
        ? last5Digits.substring(last5Digits.length - 5)
        : last5Digits;
    print("Last 5 digit: $last5Digits");

    // Get the currently logged-in user's ID
    String? senderUserId = FirebaseAuth.instance.currentUser?.uid;

    // Fetch the documents that match the last 5 digits of the phone number
    QuerySnapshot querySnapshot =
        await FirebaseFirestore.instance.collection('users').get();
    print("Query Snapshot: ${querySnapshot.docs}");

    if (querySnapshot.docs.isNotEmpty) {
      String receiverUserId = '';
      print("Receiver");
      for (QueryDocumentSnapshot<Object?> documentSnapshot
          in querySnapshot.docs) {
        Map<String, dynamic> userData =
            documentSnapshot.data() as Map<String, dynamic>;
        String userPhoneNumber = userData['phoneNumber'];
        String userUid = userData['uid'];

        // Compare the last 5 digits of the user's phone number with the provided phone number
        String userLast5Digits =
            userPhoneNumber.replaceAll(RegExp(r'[^0-9]'), '');
        userLast5Digits = userLast5Digits.length >= 5
            ? userLast5Digits.substring(userLast5Digits.length - 5)
            : userLast5Digits;

        if (userLast5Digits == last5Digits) {
          receiverUserId = userUid;
          break;
        }
      }

      print("Receiver User ID: $receiverUserId");

      if (receiverUserId.isNotEmpty) {
        // Create a new request document in the "All_Requests" collection with the UID of the receiver user
        await FirebaseFirestore.instance
            .collection('All_Requests')
            .doc(receiverUserId)
            .set({
          // 'senderUserId': senderUserId,
        });

        // Create a subcollection within the request document for the sender
        await FirebaseFirestore.instance
            .collection('All_Requests')
            .doc(receiverUserId)
            .collection('request')
            .add({
          'senderUserId': senderUserId,
          'receiverUserId': receiverUserId,
          'request_status': 'in process',
        });
      }
    }
  }

  Future<List<String>> findNearbyUsers() async {
    String? currentUserId = FirebaseAuth.instance.currentUser?.uid;

    DocumentSnapshot currentUserSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUserId)
        .get();

    if (currentUserSnapshot.exists) {
      Map<String, dynamic> currentUserData =
          currentUserSnapshot.data() as Map<String, dynamic>;
      String currentUserAddress = currentUserData['address'];
      print("currentUserAddress: $currentUserAddress");
      if (currentUserAddress.isNotEmpty) {
        try {
          List<Location> currentUserLocations =
              await locationFromAddress(currentUserAddress);
          print("currentUserLocations: $currentUserLocations");

          if (currentUserLocations.isNotEmpty) {
            Location currentUserLocation = currentUserLocations.first;
            LatLng currentUserLatLng = LatLng(
                currentUserLocation.latitude, currentUserLocation.longitude);
            print("currentUserLocation: $currentUserLocation");
            print("currentUserLatLng: $currentUserLatLng");

            QuerySnapshot querySnapshot = await FirebaseFirestore.instance
                .collection('users')
                .where('uid', isNotEqualTo: currentUserId)
                .get();

            List<String> nearbyUserIds = [];

            if (querySnapshot.docs.isNotEmpty) {
              for (QueryDocumentSnapshot<Object?> documentSnapshot
                  in querySnapshot.docs) {
                Map<String, dynamic> userData =
                    documentSnapshot.data() as Map<String, dynamic>;
                String address = userData['address'];

                if (address.isNotEmpty) {
                  try {
                    List<Location> locations =
                        await locationFromAddress(address);
                    print("Locations: $locations");

                    if (locations.isNotEmpty) {
                      Location location = locations.first;
                      LatLng otherUserLatLng =
                          LatLng(location.latitude, location.longitude);

                      Geodesy geodesy = Geodesy();
                      num distance = geodesy.distanceBetweenTwoGeoPoints(
                          currentUserLatLng, otherUserLatLng);
                      print("Distance: $distance");

                      if (distance <= 3000) {
                        nearbyUserIds.add(userData['uid']);
                      }
                    } else {
                      print('No location found for address: $address');
                    }
                  } catch (e) {
                    print('Error fetching location for address: $address');
                    print('Error message: $e');
                  }
                }
              }
            }

            // Return the list of nearby user IDs
            return nearbyUserIds;
          } else {
            print(
                'No location found for current user address: $currentUserAddress');
          }
        } catch (e) {
          print(
              'Error fetching location for current user address: $currentUserAddress');
          print('Error message: $e');
        }
      }
    }

    // Return an empty list if no nearby users found or any error occurred
    return [];
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: double.infinity,
      child: FutureBuilder(
        future: getContacts(),
        builder: (context, AsyncSnapshot snapshot) {
          if (snapshot.data == null) {
            return Center(
              child: SizedBox(
                  height: 50,
                  child: CircularProgressIndicator(
                    color: appTheme.teal500,
                  )),
            );
          }
          return ListView.builder(
              itemCount: snapshot.data.length,
              itemBuilder: (context, index) {
                Contact contact = snapshot.data[index];
                return Column(children: [
                  ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: Color(0XFF08B783),
                      radius: 20,
                      child: Icon(Icons.person, color: Colors.white),
                    ),
                    title: Text(contact.displayName),
                    subtitle: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Text(contact.phones.isNotEmpty
                            ? contact.phones[0].number
                            : 'No phone number'),
                      ],
                    ),
                    trailing: ElevatedButton(
                      style: ButtonStyle(
                        backgroundColor:
                            MaterialStateProperty.all(Color(0XFF08B783)),
                      ),
                      onPressed: () {
                        if (contact.phones.isNotEmpty) {
                          sendRequest(contact.phones[0].number);
                        } else {
                          print('No phone number available');
                        }
                      },
                      child: Text(
                        'Request',
                        style: TextStyle(
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const Divider()
                ]);
              });
        },
      ),
    );
  }

  Future<List<Contact>> getContacts() async {
    // Check if contacts permission is granted
    bool isGranted = await Permission.contacts.status.isGranted;
    print("Checking contact permission");
    if (!isGranted) {
      isGranted = await Permission.contacts.request().isGranted;
    }

    if (isGranted) {
      // Fetch all contacts
      List<Contact> allContacts = await FastContacts.getAllContacts();

      // Fetch the last 5 digits of phone numbers from the contacts
      List<String> contactLast5Digits = allContacts.map((contact) {
        if (contact.phones.isNotEmpty) {
          String phoneNumber =
              contact.phones[0].number.replaceAll(RegExp(r'[^0-9]'), '');
          return phoneNumber.length >= 5
              ? phoneNumber.substring(phoneNumber.length - 5)
              : phoneNumber;
        } else {
          return '';
        }
      }).toList();
      print("Contact Last 5 Digits: $contactLast5Digits");

      // Query and filter the Firebase users collection based on the last 5 digits of phone numbers
      QuerySnapshot querySnapshot =
          await FirebaseFirestore.instance.collection('users').get();

      // Extract the matching user phone numbers from the Firebase query result
      List<String> matchingUserPhoneNumbers = querySnapshot.docs
          .map((doc) {
            String phoneNumber =
                (doc.data() as Map<String, dynamic>)['phoneNumber'].toString();
            return phoneNumber.length >= 5
                ? phoneNumber.substring(phoneNumber.length - 5)
                : phoneNumber;
          })
          .cast<String>()
          .toList();
      print("Matching User Phone Numbers: $matchingUserPhoneNumbers");

      // Fetch the currently logged-in user's ID
      String? currentUserUid = FirebaseAuth.instance.currentUser?.uid;

      // Fetch the currently logged-in user's "friend" collection
      QuerySnapshot friendCollectionSnapshot = await FirebaseFirestore.instance
          .collection('All_Friends')
          .doc(currentUserUid)
          .collection('friend')
          .get();

      // Extract the friend user IDs from the friend collection
      // List<String> friendUserIds = friendCollectionSnapshot.docs
      //     .map((doc) =>
      //         (doc.data() as Map<String, dynamic>)['friendsUserId'].toString())
      //     .cast<String>()
      //     .toList();
      // print("Friend User IDs: $friendUserIds");
      //
      // QuerySnapshot friendPhoneNumbersSnapshot = await FirebaseFirestore
      //     .instance
      //     .collection('users')
      //     .where('uid', whereIn: friendUserIds)
      //     .get();
      // print("Friend Phone Numbers: $friendPhoneNumbersSnapshot");
      //
      // List<String> friendPhoneNumbers = friendPhoneNumbersSnapshot.docs
      //     .map((doc) =>
      //         (doc.data() as Map<String, dynamic>)['phoneNumber'].toString())
      //     .map((phoneNumber) => phoneNumber.substring(phoneNumber.length - 5))
      //     .toList();
      // print("Friend Phone Numbers: $friendPhoneNumbers");

      // Filter out the contacts that have friendPhoneNumbers matching the last 5 digits of their phone numbers
      List<Contact> filteredContacts = allContacts.where((contact) {
        if (contact.phones.isNotEmpty) {
          String contactLast5Digits =
              contact.phones[0].number.replaceAll(RegExp(r'[^0-9]'), '');
          contactLast5Digits = contactLast5Digits.length >= 5
              ? contactLast5Digits.substring(contactLast5Digits.length - 5)
              : contactLast5Digits;
          return matchingUserPhoneNumbers.contains(contactLast5Digits);

          // && !friendPhoneNumbers.contains(contactLast5Digits);
        } else {
          // Handle case where contact has no phone numbers
          return false;
        }
      }).toList();
      print("Filtered Contacts: $filteredContacts");

      return filteredContacts;
    }

    return [];
  }
}

//   Future<List<Contact>> getContacts() async {
//     // Check if contacts permission is granted
//     bool isGranted = await Permission.contacts.status.isGranted;
//     print("Abc");
//     if (!isGranted) {
//       await Permission.contacts.request().isGranted;
//     }
//
//     if (isGranted) {
//       // Fetch all contacts
//       List<Contact> allContacts = await FastContacts.getAllContacts();
//
//       // Fetch the last 5 digits of phone numbers from the contacts
//       List<String> contactLast5Digits = allContacts.map((contact) {
//         if (contact.phones.isNotEmpty) {
//           String phoneNumber = contact.phones[0].number.replaceAll(RegExp(r'[^0-9]'), '');
//           return phoneNumber.length >= 5 ? phoneNumber.substring(phoneNumber.length - 5) : phoneNumber;
//         } else {
//           return '';
//         }
//       }).toList();
//       print("Contact Last 5 Digits: $contactLast5Digits");
//
//       // Query and filter the Firebase users collection based on the last 5 digits of phone numbers
//       QuerySnapshot querySnapshot = await FirebaseFirestore.instance.collection('users').get();
//
//       // Extract the matching user phone numbers from the Firebase query result
//       List<String> matchingUserPhoneNumbers = querySnapshot.docs.map((doc) {
//         String phoneNumber = (doc.data() as Map<String, dynamic>)['phoneNumber'].toString();
//         return phoneNumber.length >= 5 ? phoneNumber.substring(phoneNumber.length - 5) : phoneNumber;
//       }).cast<String>().toList();
//       print("Matching User Phone Numbers: $matchingUserPhoneNumbers");
//
//       // Fetch the currently logged-in user's ID
//       String? currentUserUid = FirebaseAuth.instance.currentUser?.uid;
//
//       // Fetch the currently logged-in user's "friend" collection
//       QuerySnapshot friendCollectionSnapshot = await FirebaseFirestore.instance.collection('All_Friends').doc(currentUserUid).collection('friend').get();
//
// // Extract the friend user IDs from the friend collection
//       List<String> friendUserIds = friendCollectionSnapshot.docs.map((doc) => (doc.data() as Map<String, dynamic>)['friendsUserId'].toString()).cast<String>().toList();
//       print("Friend User IDs: $friendUserIds");
//
//
//       QuerySnapshot friendPhoneNumbersSnapshot = await FirebaseFirestore.instance.collection('users').where('uid', whereIn: friendUserIds).get();
//       print("Friend Phone Numbers: $friendPhoneNumbersSnapshot");
//
//       List<String> friendPhoneNumbers = friendPhoneNumbersSnapshot.docs
//           .map((doc) => (doc.data() as Map<String, dynamic>)['phoneNumber'].toString())
//           .map((phoneNumber) => phoneNumber.substring(phoneNumber.length - 5))
//           .toList();
//       print("Friend Phone Numbers: $friendPhoneNumbers");
//
// // Filter out the contacts that have friendPhoneNumbers matching the last 5 digits of their phone numbers
//       List<Contact> filteredContacts = allContacts.where((contact) {
//         if (contact.phones.isNotEmpty) {
//           String contactLast5Digits = contact.phones[0].number.replaceAll(RegExp(r'[^0-9]'), '');
//           contactLast5Digits = contactLast5Digits.length >= 5 ? contactLast5Digits.substring(contactLast5Digits.length - 5) : contactLast5Digits;
//           return matchingUserPhoneNumbers.contains(contactLast5Digits) && !friendPhoneNumbers.contains(contactLast5Digits);
//         } else {
//           // Handle case where contact has no phone numbers
//           return false;
//         }
//       }).toList();
//       print("Filtered Contacts: $filteredContacts");
//
//       return filteredContacts;
//     }
//
//     return [];
//   }
