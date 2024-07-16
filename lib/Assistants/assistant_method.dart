import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:geolocator/geolocator.dart';
import 'package:hitchify/Assistants/request_assistant.dart';
import 'package:hitchify/global/global.dart';
import 'package:hitchify/models/user_model.dart';
import 'package:hitchify/UI/auth/loginWithPhone.dart';
import 'package:hitchify/global/map_key.dart';
import 'package:hitchify/models/directions.dart';
import 'package:http/http.dart';

class AssistantMethods{
  static void readCurrentOnlineUserInfo() async{
    final auth = FirebaseAuth.instance;
    final user = auth.currentUser;
    DatabaseReference userRef = FirebaseDatabase.instance
    .ref().child("users").child(user!.uid);

    userRef.once().then((snap){
      if(snap.snapshot.value!= null){
        userModelCurrentInfo = UserModel.fromSnapShot(snap.snapshot);
      }
    });

  }

  static Future<String> searchAddressForGeographicCoOrdinates(Position position,context) async{

    String apiUrl = "https://maps.googleapis.com/maps/api/geocode/json?latlng=${position.latitude},${position.longitude}&key=$mapKey";
    String humanReadableAddress = "";

    var requestResponse = await RequestAssistant.receiveRequest(apiUrl);

    if(requestResponse != 'Error Occured Failed No Response'){
      humanReadableAddress = requestResponse["results"][0]["formatted_address"];

      Directions userPickerAddress = Directions();
      userPickerAddress.locationLongitude = position.longitude;
      userPickerAddress.locationLatitude = position.latitude;
      userPickerAddress.locationName = humanReadableAddress;

      // Provider.of<AppInfo>(context,listen:false).updatePickUpLocationAddress(userPickerAddress);

    }
    return humanReadableAddress;
  }
}
