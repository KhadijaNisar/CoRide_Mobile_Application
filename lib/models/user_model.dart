import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class UserModel {
  String? id;
  String? displayName;
  String? address;
  String? cnic;
  String? email;
  String? image;

  UserModel({
   this.displayName,this.address,this.cnic,this.email,this
  .id,this.image
});

  UserModel.fromSnapShot(DataSnapshot snaps){
    address= (snaps.value as dynamic)["phone"];
    email= (snaps.value as dynamic)["email"];
    cnic= (snaps.value as dynamic)["cnic"];
    displayName= (snaps.value as dynamic)["displayName"];
    image= (snaps.value as dynamic)["image"];
    id = snaps.key;
  }
}