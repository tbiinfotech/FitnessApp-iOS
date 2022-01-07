//
//  FirebaseSession.swift
//  TODO
//
//
import UIKit
import Firebase
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage

class FirebaseSession: NSObject {
    
    //MARK: Properties
    
    var session = User()
    var isLoggedIn: Bool?
    var allUsers = [[String: Any]]()
    
    let db = Firestore.firestore()

    // Get a non-default Storage bucket
    // Create a storage reference from our storage service

    let storageRef = Storage.storage(url:"gs://XXXX.XXXX.com").reference()

    var likedPosts = [String]()

    var directChats = [[String: Any]]()
    var challengesArray = [[String: Any]]()
    var subscribedChallenges = [[String: Any]]()
    var challengesCheckedInArray = [[String: Any]]()

    var thundrMeals = [[String: Any]]()
    var shoppingList = [[String: Any]]()
    var checkedInShoppingList = [[String: Any]]()
    var savedMeals = [[String: Any]]()

    var macrosData = [String: Any]()
    
    var currentMealPlan = [String: Any]()
    var sampleMealPlanDict = [String: Any]()

    
    
    var currentWeekMacrosData = [String: Any]()
    var mealPlanGroceryList = [[String: Any]]()

    ////////
    
    var aValues = (calorie: 0.0, protein: 0.0, carbs: 0.0, fat: 0.0)
    var bValues = (calorie: 0.0, protein: 0.0, carbs: 0.0, fat: 0.0)
    var cValues = (calorie: 0.0, protein: 0.0, carbs: 0.0, fat: 0.0)
    var aPlusValues = (calorie: 0.0, protein: 0.0, carbs: 0.0, fat: 0.0)
    
    var fromHome = false
    
    
    var isShredChallengeSubscribed = false
    var isManiaChallengeSubscribed = false
    var isAnarchyChallengeSubscribed = false
    var isNutritionSubscribed = false

    static let shared : FirebaseSession = {
        let instance = FirebaseSession()
        return instance
    }()
    


    //MARK: Functions
    func listen() {
        _ = Auth.auth().addStateDidChangeListener { (auth, user) in
            if let user = user {
                self.session = User(uid: user.uid, email: user.email ?? "") ?? User()
                self.isLoggedIn = true
                self.getUserDetals(uid: user.uid, email: user.email ?? "")
                self.getAllUsers()
                self.getUserSubscriptions()
                self.getMyLikedPosts()
                self.getMyDirectChatList()
                self.getMacroBaselineCalculations(uid: user.uid)
                self.getChallenges()
                self.getUserSubscribedChallenges()
                self.getChallengesCheckedIn()
                self.getSampleMealPlan(uid: user.uid)

                self.getShoppingCheckedIn()
                self.getSavedMeals()
                            
                self.getThundrbroMeals()
                self.getShoppingList()

            } else {
                self.isLoggedIn = false
                self.session = User()
            }
        }
    }
    

    /// - Description: Call this function when user redirect to app using link
    /// - Parameters:
    ///   - handler: Use to handle the callback. This block will be called and result will be
    ///                 success or failed.

    func createUser(withEmail email: String, password: String, handler: @escaping AuthDataResultCallback) {
        Auth.auth().createUser(withEmail: email, password: password, completion: handler)
      }
        
    /// - Description: Call this function when user redirect to app using link
    /// - Parameters:
    ///   - handler: Use to handle the callback. This block will be called and result will be
    ///                 success or failed.

    func signIn(withEmail email: String, password: String, handler: @escaping AuthDataResultCallback) {
        Auth.auth().signIn(withEmail: email, password: password, completion: handler)
      }

    func resetPassword(withEmail email: String, handler: @escaping SendPasswordResetCallback) {
        Auth.auth().sendPasswordReset(withEmail: email, completion: handler)
    }

    
    /// - Description: Call this function to logout user.

    func logOut() {
        try! Auth.auth().signOut()
        self.isLoggedIn = false
        self.session = User()
//        UserData.shared.session = self
    }
    
    
    func getUserSubscriptions() {

        db.collection("Users").document(FirebaseSession.shared.session.uid).collection("SubscriptionDetails").document("subscription").addSnapshotListener { (snapshot, err) in
            if let err = err {
                print("Error getting documents: \(err)")
            } else {

                if let snapshot = snapshot, snapshot.exists {
                    if let data = snapshot.data() {
                  
                        if let shredChallenge = data["shredChallenge"] as? [String: Any] {
                            if let isSubscribed = shredChallenge["subscribed"] as? Bool, isSubscribed == true {
                                self.isShredChallengeSubscribed = true
                            }
                        }
                        
                        if let muscleMania = data["muscleMania"] as? [String: Any] {
                            if let isSubscribed = muscleMania["subscribed"] as? Bool, isSubscribed == true {
                                self.isManiaChallengeSubscribed = true
                            }
                        }

                        if let muscleAnarchy = data["muscleAnarchy"] as? [String: Any] {
                            if let isSubscribed = muscleAnarchy["subscribed"] as? Bool, isSubscribed == true {
                                self.isAnarchyChallengeSubscribed = true
                            }
                        }

                        if let nutrition = data["macroCal"] as? [String: Any] {
                            if let isSubscribed = nutrition["subscribed"] as? Bool, isSubscribed == true {
                                self.isNutritionSubscribed = true
                            }
                        }
                        
                    }
                    
                } else {
                    print("not exists")
                    
                    let data = ["shredChallenge": ["subscribed": false, "type": "Consumable"],
                                "muscleMania": ["subscribed": false, "type": "Consumable"],
                                "muscleAnarchy": ["subscribed": false, "type": "Auto-Renewable Subscription"],
                                "macroCal": ["subscribed": false, "type": "Auto-Renewable Subscription"],
                    ]
                    
                    self.db.collection("Users").document(FirebaseSession.shared.session.uid).collection("SubscriptionDetails").document("subscription").setData(data)
                    
                }

            }
        }

    }

    
    /// - Description: Call this function to add user details on Firebase
    /// - Parameters:
    ///   - uid: user id of logedin user
    ///   - email: email of user

    func addUserDetails(uid: String, email: String) {
           //Generates number going up as time goes on, sets order of TODO's by how old they are.
        let userData = ["userid": uid,
                        "email": email]
    
          // Add a new document with a generated ID
        self.db.collection("Users").document(uid).setData(userData) { (error) in
          print("Error adding document: \(String(describing: error))")
        }
    }

    /// - Description: Call this function to get user details fom Firebase CloudStore
    /// - Parameters:
    ///   - uid: user id of logedin user
    ///   - email: email of user

    func getUserDetals(uid: String, email: String) {
          self.db.collection("Users").document(uid).getDocument { (snapshot, error) in
              if let document = snapshot, document.exists {

                if let documentData = document.data() {
                    UserDefaults.standard.setValue(FirebaseSession.shared.session.uid, forKey: "user_id")
                    
                    if let username = documentData["name"] as? String {
                        self.session.username = username
                        
                        UserDefaults.standard.setValue(username, forKey: "username")
                    }
                    
                    if let thumbnail = documentData["imageurl"] as? String {
                        self.session.thumbnail = thumbnail
                        
                        UserDefaults.standard.setValue(thumbnail, forKey: "thumbnail")

                    }
                    
                    if let nickname = documentData["nickname"] as? String {
                        self.session.nickname = nickname
                        
                        UserDefaults.standard.setValue(nickname, forKey: "nickname")
                    }
                    
                    if let location = documentData["location"] as? String {
                        self.session.location = location
                        UserDefaults.standard.setValue(location, forKey: "location")
                    }
                    
                    if let dob = documentData["dob"] as? String {
                        self.session.birthday = dob
                        UserDefaults.standard.setValue(dob, forKey: "dob")
                    }

                    if let gender = documentData["gender"] as? String {
                        self.session.gender = gender
                        
                        UserDefaults.standard.setValue(gender, forKey: "gender")
                    }
                    
                    if let workout = documentData["workout"] as? String {
                        self.session.workout = workout                        
                        UserDefaults.standard.setValue(workout, forKey: "workout")
                    }
                  }
              } else {
                print("Document does not exist")
                /// - Description: if document doesn't exist, add user details to firebase
                self.addUserDetails(uid: uid, email: email)
            }
          }
      }
    
    func getUserDetailsFromPreferences() {
        if let username = UserDefaults.standard.value(forKey: "username") as? String {
            self.session.username = username
        }
        
        if let thumbnail = UserDefaults.standard.value(forKey: "thumbnail") as? String {
            self.session.thumbnail = thumbnail
        }

        if let nickname = UserDefaults.standard.value(forKey: "nickname") as? String {
            self.session.nickname = nickname
        }

        if let location = UserDefaults.standard.value(forKey: "location") as? String {
            self.session.location = location
        }

        if let dob = UserDefaults.standard.value(forKey: "dob") as? String {
            self.session.birthday = dob
        }

        
    }

    /// - Description: Call this function to update user details in Firebase CloudStore
    /// - Parameters:
    ///   - uid: user id of logedin user
    ///   - data: data that needs to be update
    
    func updateUserDetails(uid: String, data: [String: Any]) {
          // Add a new document with a generated ID
        self.db.collection("Users").document(uid).updateData(data) { (error) in
            print("Error adding document: \(String(describing: error))")
            self.getUserDetals(uid: uid, email: FirebaseSession.shared.session.email)
        }
    }
    
    
    func editProfile(name:String,nickName:String,dateOfBirth:String,gender:String,workout:String,location:String,image:UIImage, completion: @escaping (Bool) -> Void){

        var data = NSData()

        if let imagedata = image.jpegData(compressionQuality: 0.8) as NSData? {
            data = imagedata
        }
        
        // set upload path
        //  let filePath = "\(\(FIRAuth.auth()!.currentUser!.uid)/\("ProfileImages"))" // path where you wanted to store img in storage
        
        let filePath = "\(Auth.auth().currentUser!.uid)/\("ProfileImages")"
        let metaData = StorageMetadata()
        metaData.contentType = "image/jpg"
        
        let storageRef = Storage.storage().reference()
        storageRef.child(filePath).putData(data as Data, metadata: metaData){(metaData,error) in
            if let error = error {
                print(error.localizedDescription)
                return
            }else{
                storageRef.child(filePath).downloadURL(completion: {(url, error) in
                    if error != nil {
                        print(error!.localizedDescription)
                        return
                    }
                    let downloadURL = url?.absoluteString
                    
                    let docData: [String: Any] = [
                        "name": name,
                        "nickname": nickName,
                        "dob": dateOfBirth,
                        "gender": gender,
                        "imageurl": downloadURL!,
                        "workout": workout,
                        "location": location,
                    ]
                    
                    print(docData)
                    
                    self.updateUserDetails(uid: FirebaseSession.shared.session.uid, data: docData)
                })
            }
        }
    }
    
    
    func uploadProfilePic(image: UIImage, completion: @escaping (Bool) -> Void) {
        var data = NSData()

        if let imagedata = image.jpegData(compressionQuality: 0.8) as NSData? {
            data = imagedata
        }
        
        // set upload path
        //  let filePath = "\(\(FIRAuth.auth()!.currentUser!.uid)/\("ProfileImages"))" // path where you wanted to store img in storage
        
        let filePath = "\(Auth.auth().currentUser!.uid)/\("ProfileImages")"
        let metaData = StorageMetadata()
        metaData.contentType = "image/jpg"
        
        let storageRef = Storage.storage().reference()
        storageRef.child(filePath).putData(data as Data, metadata: metaData){(metaData,error) in
            if let error = error {
                print(error.localizedDescription)
                return
            } else {
                storageRef.child(filePath).downloadURL(completion: {(url, error) in
                    if error != nil {
                        print(error!.localizedDescription)
                        return
                    }
                    let downloadURL = url?.absoluteString
                    completion(true)
                    let data = ["imageurl": downloadURL!]
                    
                    self.updateUserDetails(uid: self.session.uid, data: data)
                    
                })
            }
        }
    }
 
    
    func uploadMessageBoardPhoto(imageData: Data, isGif: Bool, completion: @escaping (String) -> Void) {
        
        let metadata = StorageMetadata()
        var imageExt = ".jpg"
        if isGif {
            metadata.contentType = "image/gif"
            imageExt = ".gif"
        } else {
            metadata.contentType = "image/jpeg"
        }

        // Create a reference to 'images/name.jpg'
        let imagesRef = self.storageRef.child("messageBoard_images/image\(UUID().uuidString)\(imageExt)")
 
        _ = imagesRef.putData(imageData, metadata: metadata) { (metadata, error) in
            guard let metadata = metadata else {
                // Uh-oh, an error occurred!
                return
            }
            // Metadata contains file metadata such as size, content-type.
            let _ = metadata.size
            // You can also access to download URL after upload.
            imagesRef.downloadURL { (url, error) in
                guard let downloadURL = url else {
                    // Uh-oh, an error occurred!
                    return
                }
                    // print("Size: %@, URL: %@", size, downloadURL)
                        
                completion(downloadURL.absoluteString)
            }
        }
    }
    
    func getAllUsers() {
        self.db.collection("Users").addSnapshotListener(includeMetadataChanges: false) {(snapshot, error) in
            if let error = error {
                print("add Listner error: ", error.localizedDescription as Any)
            } else if let snapshot = snapshot {
                
                snapshot.documentChanges.forEach { diff in
                    if (diff.type == .added) {
                        print("New Task: \(diff.document.data())")

                        if diff.document.data()["userid"] as? String != FirebaseSession.shared.session.uid {
                            if let name = diff.document.data()["name"] as? String, name.count > 0 {
                                FirebaseSession.shared.allUsers.append(diff.document.data())
                            }
                        }
                    }
                    if (diff.type == .modified) {
                        print("Modified Task: \(diff.document.data())")
                        
                        FirebaseSession.shared.allUsers = FirebaseSession.shared.allUsers.map({
                            var dict = $0
                            if dict["userid"] as? String == diff.document.documentID {
                                dict = diff.document.data()
                            }
                            return dict
                        })
                    }
                    if (diff.type == .removed) {
                        print("Removed Task: \(diff.document.data())")
                    }
                }
            }
        }
    }
    
    //MARK: MessageBoard
    
    func addPostInMessageBoard(uid: String, data: [String: Any]) {
          // Add a new document with a generated ID

        self.db.collection("MessageBoard").addDocument(data: data) { (error) in
            print("Error adding document: \(String(describing: error))")
        }
    }

    func updatePostInMessageBoard(documentId: String, data: [String: Any]) {
          // Add a new document with a generated ID
        self.db.collection("MessageBoard").document(documentId).updateData(data) { (error) in
            print("Error adding document: \(String(describing: error))")
        }
    }

    func addLikesInMessageBoard(documentId: String, data: [String: Any]) {
          // Add a new document with a generated ID
        self.db.collection("Users").document(FirebaseSession.shared.session.uid).collection("likedPosts").document(documentId).setData(data)
    }
    
    func removeLikedPostInMessageBoard(documentId: String) {
          // Add a new document with a generated ID
        self.db.collection("Users").document(FirebaseSession.shared.session.uid).collection("likedPosts").document(documentId).delete()
    }
    
    func getMyLikedPosts() {
        self.db.collection("Users").document(FirebaseSession.shared.session.uid).collection("likedPosts").addSnapshotListener(includeMetadataChanges: false) { [self] (snapshot, error) in
            if let error = error {
                print("add Listner error: ", error.localizedDescription as Any)
            } else if let snapshot = snapshot {
                
                snapshot.documentChanges.forEach { diff in
                    if (diff.type == .added) {
                        print("New Task: \(diff.document.data())")
                        self.likedPosts.append(diff.document.documentID)
                    }
                    if (diff.type == .modified) {
                        print("Modified Task: \(diff.document.data())")
                    }
                    if (diff.type == .removed) {
                        print("Removed Task: \(diff.document.data())")
                        self.likedPosts.removeAll { value in
                             return value == diff.document.documentID
                         }
                    }
                }
            }
        }

    }

    func addCommentInMessageBoard(documentId: String, data: [String: Any]) {
          // Add a new document with a generated ID
        self.db.collection("MessageBoard").document(documentId).collection("Comments").addDocument(data: data)
    }

    func getMessageBoardPosts(completion: @escaping ([String: Any]) -> Void, updationComments: @escaping ([String: Any]) -> Void, updation: @escaping ([String: Any]) -> Void) {

        self.db.collection("MessageBoard").order(by: "timestamp", descending: false).addSnapshotListener(includeMetadataChanges: false) { (snapshot, error) in
            if let error = error {
                print("add Listner error: ", error.localizedDescription as Any)
            } else if let snapshot = snapshot {
//                print("add Listner snaphot: ", snapshot.documents)
                
                snapshot.documentChanges.forEach { diff in
                    if (diff.type == .added) {
                        print("New Task: \(diff.document.data())")
                        
                        var data = diff.document.data()
                        
                        data["documentId"] = diff.document.documentID
                        
                        let user = FirebaseSession.shared.allUsers.filter { $0["userid"] as? String == diff.document.data()["sender"] as? String }
                        if user.count > 0 {
                            data["name"] = user[0]["name"]
                            data["imageurl"] = user[0]["imageurl"]
                            data["status"] = user[0]["status"]
                        }

                        completion(data)
                        
                        self.db.collection("MessageBoard").document(diff.document.documentID).collection("Comments").order(by: "timestamp", descending: false).addSnapshotListener(includeMetadataChanges: false) { (snapshot, error) in
                        
                            if let error = error {
                                print("add Listner error: ", error.localizedDescription as Any)
                            } else if let snapshot = snapshot {
                                
                                var comments = [[String: Any]]()
                                
                                snapshot.documents.forEach { document in
//                                    if (commentDiff.type == .added) {
                                        print("New Comment Task: \(document.data())")
                                      
                                        var commentDict = document.data()
                                        
                                        if commentDict["comment_by"] as? String  == FirebaseSession.shared.session.uid {
                                            commentDict["username"] = FirebaseSession.shared.session.username
                                            commentDict["profile_url"] = FirebaseSession.shared.session.thumbnail
                                        } else {
                                            let user = FirebaseSession.shared.allUsers.filter { $0["userid"] as? String == document.data()["comment_by"] as? String }
                                            if user.count > 0 {
                                                commentDict["username"] = user[0]["name"]
                                                commentDict["profile_url"] = user[0]["imageurl"]
                                            }
                                        }
                                        
                                        comments.append(commentDict)
//                                    }
                                }
                                    updationComments([ "documentId": diff.document.documentID,
                                                       "comments": comments
                                ])
                            }
                        }

                    }
                    if (diff.type == .modified) {
                        print("Modified Task: \(diff.document.data())")
                        
                        updation([ "documentId": diff.document.documentID,
                                  "dict": diff.document.data()])

                    }
                    if (diff.type == .removed) {
                        print("Removed Task: \(diff.document.data())")
                    }
                }
            }
        }

    }
    
    func addReportToMessageboard(postId: String, data: [String: Any]) {
        self.db.collection("ReportMessageBoard").document(postId).setData(data)
    }

    func updateReportToMessageboard(postId: String, data: [String: Any]) {
        self.db.collection("ReportMessageBoard").document(postId).updateData(data)
    }

    
    //MARK: Direct Messages
    
    
    func sendNewDirectMessage(senderId: String, receiverId: String, data: [String: Any], completion: @escaping (String) -> Void) {
          // Add a new document with a generated ID

        let ref = self.db.collection("Messages").document()
            ref.collection("chat").addDocument(data: data) { (error) in
            print("Error adding document: \(String(describing: error))")
                print("document id:", ref.documentID)
                
                let senderData = [
                    "chat_path": ref.documentID,
                    "other_user_id": receiverId,
                    "last_Message": data["text"],
                    "message_type": data["type"],
                    "timestamp": data["timestamp"],
                    "sender": senderId,
                    "unread_message": 0,
                    "seen": true
                ]

                let recieveData = [
                    "chat_path": ref.documentID,
                    "other_user_id": senderId,
                    "last_Message": data["text"],
                    "message_type": data["type"],
                    "timestamp": data["timestamp"],
                    "sender": senderId,
                    "unread_message": 1,
                    "seen": false
                ]

                
                self.addChatPathInUserCollection(userId: senderId, chatPath: ref.documentID, data: senderData as [String : Any])
                self.addChatPathInUserCollection(userId: receiverId, chatPath: ref.documentID, data: recieveData as [String : Any])
                completion(ref.documentID)
            }
    }

    func addChatPathInUserCollection(userId: String, chatPath: String, data: [String: Any]) {
        self.db.collection("Users").document(userId).collection("Chats").document(chatPath).setData(data)
    }
    
    /////////
    
    
    
    func sendDirectMessage(chatpath: String, senderId: String, receiverId: String, data: [String: Any]) {
          // Add a new document with a generated ID
        
        self.db.collection("Messages").document(chatpath).collection("chat").addDocument(data: data) { (error) in
            print("Error adding document: \(String(describing: error))")
                
                let senderData = [
                    "chat_path": chatpath,
                    "other_user_id": receiverId,
                    "last_Message": data["text"],
                    "message_type": data["type"],
                    "timestamp": data["timestamp"],
                    "sender": senderId,
                    "unread_message": 0,
                    "seen": true
                ]

                let recieveData = [
                    "chat_path": chatpath,
                    "other_user_id": senderId,
                    "last_Message": data["text"],
                    "message_type": data["type"],
                    "timestamp": data["timestamp"],
                    "sender": senderId,
                    "seen": false
                ]

                
                self.updateChatPathInUserCollection(userId: senderId, chatPath: chatpath, data: senderData as [String : Any])
                self.updateChatPathInUserCollection(userId: receiverId, chatPath: chatpath, data: recieveData as [String : Any])

        }
    }

    func updateChatPathInUserCollection(userId: String, chatPath: String, data: [String: Any]) {
        self.db.collection("Users").document(userId).collection("Chats").document(chatPath).updateData(data)
    }

    
    func updateUnreadMessagesInDirectChat(documentPath: String, chatPath: String, data: [String: Any]) {
        self.db.collection("Messages").document(chatPath).collection("chat").document(documentPath).updateData(data)
    }

    
    
    func getMyDirectChatList() {
        self.db.collection("Users").document(FirebaseSession.shared.session.uid).collection("Chats").order(by: "timestamp", descending: true).addSnapshotListener(includeMetadataChanges: false) { [self] (snapshot, error) in
            if let error = error {
                print("add Listner error: ", error.localizedDescription as Any)
            } else if let snapshot = snapshot {
                
                snapshot.documentChanges.forEach { diff in
                    if (diff.type == .added) {
                        print("New Direct Task: \(diff.document.data())")
                        
                        var data = diff.document.data()
                        
                        let user = FirebaseSession.shared.allUsers.filter { $0["userid"] as? String == diff.document.data()["other_user_id"] as? String }
                        if user.count > 0 {
                            data["name"] = user[0]["name"]
                            data["imageurl"] = user[0]["imageurl"]
                            data["status"] = user[0]["status"]
                        }

                        
                        self.directChats.append(data)
                    }
                    if (diff.type == .modified) {
                        print("Modified Direct Task: \(diff.document.data())")
                        
                        directChats = directChats.map({
                            var dict = $0
                            
                            if dict["chat_path"] as? String == diff.document.documentID {
                             
                                dict["last_Message"] = diff.document.data()["last_Message"]
                                dict["timestamp"] = diff.document.data()["timestamp"]
                                dict["seen"] = diff.document.data()["seen"]
                                dict["message_type"] = diff.document.data()["message_type"]
                                dict["sender"] = diff.document.data()["sender"]

                            }
                            return dict
                        })
                        
                    }
                    if (diff.type == .removed) {
                        print("Removed Task: \(diff.document.data())")
                    }
                }
            }
        }

    }

    
    func getDirectMessages(chatPath: String, completion: @escaping ([String: Any]) -> Void, updation: @escaping ([String: Any]) -> Void) {

        self.db.collection("Messages").document(chatPath).collection("chat").order(by: "timestamp", descending: false).addSnapshotListener(includeMetadataChanges: false) { (snapshot, error) in
            if let error = error {
                print("add Listner error: ", error.localizedDescription as Any)
            } else if let snapshot = snapshot {
//                print("add Listner snaphot: ", snapshot.documents)
                
                snapshot.documentChanges.forEach { diff in
                    if (diff.type == .added) {
                        print("New Task: \(diff.document.data())")
                        
                        var data = diff.document.data()
                        
                        data["documentId"] = diff.document.documentID

                        completion(data)
                        
                    }
                    if (diff.type == .modified) {
                        print("Modified Task: \(diff.document.data())")
                        
                        updation([ "documentId": diff.document.documentID,
                                  "dict": diff.document.data()])
                    }
                    if (diff.type == .removed) {
                        print("Removed Task: \(diff.document.data())")
                    }
                }
            }
        }
    }

    
    //Macro Calculator
    
    func getSampleMealPlan(uid: String) {
        if uid.count == 0 {
            return
        }
        
        self.db.collection("MacrosCalculation").document(uid).collection("MyMealPlan").document("MealPlan").addSnapshotListener({ (snapshot, error) in
            if let document = snapshot, document.exists {
                
              if let documentData = document.data() {
                self.currentMealPlan = documentData
                
                self.getMealPlanAndGrocery()
              }
            } else {
              print("Document does not exist")
            }
        })
    }

    
    func getMealPlanAndGrocery() {

        let goal = currentMealPlan["goal"] as? String ?? ""
        let mealPlan = currentMealPlan["plan"] as? String ?? ""

        
        db.collection("MealPlans").document(goal).collection("MealPlans").document(mealPlan).getDocument { (snapshot, error) in
            if let err = error {
                print("Error getting documents: \(err)")
            } else {
                if let data = snapshot?.data() {
                    print(data)
                    self.sampleMealPlanDict = data
                    
                }
            }
        }
        
        db.collection("MealPlans").document(goal).collection("GroceryList").getDocuments { [self] (snapshot, error) in

//        db.collection("MealPlans").document(goal).collection("GroceryList").getDocuments(completion: { (snapshot, error) in
            if let err = error {
                print("Error getting documents: \(err)")
            } else {
                if let documents = snapshot?.documents {
                    print(documents)
                    
                    for document in documents {
                        self.mealPlanGroceryList.append(document.data())
                    }
                }
            }
        }
    }
    
    func saveMacroBaselineCalculations(userid: String, data: [String: Any]) {
          // Add a new document with a generated ID
        
        self.db.collection("MacrosCalculation").document(userid).setData(data, completion: { (error) in
            print("Error adding document: \(String(describing: error))")
            FirebaseSession.shared.getMacroBaselineCalculations(uid: userid)
        })
    }
    
    
    func getMacroBaselineCalculations(uid: String) {
        if uid.count == 0 {
            return
        }
        
        self.db.collection("MacrosCalculation").document(uid).addSnapshotListener({ (snapshot, error) in
            if let document = snapshot, document.exists {
                
              if let documentData = document.data() {
                self.macrosData = documentData
                  
                let weekProgress = self.macrosData["weekInProgress"] as? Int ?? 1
                  
                let nextCheckInDateStr = self.macrosData["nextCheckInDate"] as? String
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "dd-MM-yyyy"

                let nextCheckInDate = dateFormatter.date(from: nextCheckInDateStr ?? "") ?? Date()
                self.getWeeklyCalculations(uid: uid, week: weekProgress, nextCheckInDate: nextCheckInDate)
              }
            } else {
              print("Document does not exist")
            }
        })
      }
    
    func saveWeeklyData(userid: String, weekPath: String, data: [String: Any]) {
        // Add a new document with a generated ID
        
        self.db.collection("MacrosCalculation").document(userid).collection("WeeklyCheckIn").document(weekPath).setData(data, completion: { (error) in
            print("Error adding document: \(String(describing: error))")
        })
    }

    func getWeeklyCalculations(uid: String, week: Int, nextCheckInDate: Date) {
        let weekInProgress = macrosData["weekInProgress"] as? Int ?? 1
        
        var documentPath = "Week 1"
        
        switch weekInProgress {
        case 1:
            documentPath = "Week 1"
        case 2:
            documentPath = "Week 2"
        case 3:
            documentPath = "Week 3"
        case 4:
            documentPath = "Week 4"
        case 5:
            documentPath = "Week 5"
        case 6:
            documentPath = "Week 6"
        case 7:
            documentPath = "Week 7"

        default:
            break
        }

        self.db.collection("MacrosCalculation").document(uid).collection("WeeklyCheckIn").document(documentPath).getDocument { (snapshot, error) in
              if let document = snapshot, document.exists {
                  

                
                if let documentData = document.data() {
                    self.currentWeekMacrosData = documentData

                    var goal = self.currentWeekMacrosData["goal"] as? String ?? ""
                    var goalScenario = "Scenario 1"
                    
                    var baselineCalorie = self.currentWeekMacrosData["baselineCalorie"] as? Int ?? 1
                    let baselineScenario = self.currentWeekMacrosData["baselineScenario"] as? String ?? ""

                    let weekStartWeight = self.currentWeekMacrosData["weekStartWeight"] as? Int ?? 1
                    let weekEndWeight = self.currentWeekMacrosData["weekEndWeight"] as? Int ?? 1

                    var weekProgress = week
                    let currentDate = Date()

                    if currentDate > nextCheckInDate  {
                        print("nextCheckInDate is earlier than currentDate")
                        
                        // Increase the week progress
                        weekProgress += 1
                        
                        if weekProgress == 5 {
                            // add 10% to baseline
                            baselineCalorie = Int(Double(baselineCalorie)*0.1 + Double(baselineCalorie))
                        }
                        
                        if weekProgress == 8 {
                            // add 10% to baseline
                            baselineCalorie = Int(Double(baselineCalorie)*0.1 + Double(baselineCalorie))
                        }
                        
                        if weekProgress == 13 {
                            // Change goal to maintain
                            goal = "maintain"
                        }
                        
                        let weightDiff = weekStartWeight - weekEndWeight
                        
                        if goal == "weightloss" {
                            if weightDiff > 5 {
                                goalScenario = "Scenario 1"
                            } else if weightDiff > 0 && weightDiff < 5 {
                                goalScenario = "Scenario 2"
                            } else if weightDiff <= 0 {
                                goalScenario = "Scenario 3"
                            }
                        } else if goal == "recompositon" {
                            if weightDiff > 2 {
                                goalScenario = "Scenario 1"
                            } else if weightDiff > -2 && weightDiff < 2 {      //   -2 < x > 2
                                goalScenario = "Scenario 2"
                            } else if weightDiff > 2 {
                                goalScenario = "Scenario 3"
                            }
                        } else if goal == "maintain" {
                            if weightDiff > 2 {
                                goalScenario = "Scenario 1"
                            } else if weightDiff > -2 && weightDiff < 2 {      //   -2 < x > 2
                                goalScenario = "Scenario 2"
                            } else if weightDiff > 2 {
                                goalScenario = "Scenario 3"
                            }
                        } else if goal == "gain" {
                            if weightDiff < 0 {
                                goalScenario = "Scenario 1"
                            } else if weightDiff > 0 && weightDiff < 4 {
                                goalScenario = "Scenario 2"
                            } else if weightDiff > 4 {
                                goalScenario = "Scenario 3"
                            }
                        }

                        //////////
                        
                        var selectedScenario = [String]()
                        var index = 0
                        
                        if weekProgress % 4 == 0 {
                            // index 3
                            index = 3
                        } else if weekProgress % 3 == 0 {
                            // index 2
                            index = 2
                        } else if weekProgress % 2 == 0 {
                            // index 1
                            index = 1
                        } else if weekProgress % 1 == 0 {
                            // index 0
                            index = 0
                        }

                        
                        if goal == "gain" {
                            self.calculateGainValues(baselineCalorie: baselineCalorie)

                            if goalScenario == "Scenario 1" {
                                selectedScenario = gainScenario1[index]
                            } else if goalScenario == "Scenario 2" {
                                selectedScenario = gainScenario2[index]
                            } else if goalScenario == "Scenario 3" {
                                selectedScenario = gainScenario3[index]
                            }

                        } else if goal == "weightloss" {
                            self.calculateLoseWeightValues(baselineCalorie: baselineCalorie)

                            if goalScenario == "Scenario 1" {
                                selectedScenario = loseScenario1[index]
                            } else if goalScenario == "Scenario 2" {
                                selectedScenario = loseScenario2[index]
                            } else if goalScenario == "Scenario 3" {
                                selectedScenario = loseScenario3[index]
                            }

                        } else if goal == "maintain" {
                            self.calculateMaintainValues(baselineCalorie: baselineCalorie)
                            
                            if goalScenario == "Scenario 1" {
                                selectedScenario = maintainScenario1[index]
                            } else if goalScenario == "Scenario 2" {
                                selectedScenario = maintainScenario2[index]
                            } else if goalScenario == "Scenario 3" {
                            }
                            selectedScenario = maintainScenario3[index]

                        } else if goal == "recompositon" {
                            self.calculateRecompositionValues(baselineCalorie: baselineCalorie)

                            if goalScenario == "Scenario 1" {
                                selectedScenario = recompostionScenario1[index]
                            } else if goalScenario == "Scenario 2" {
                                selectedScenario = recompostionScenario2[index]
                            } else if goalScenario == "Scenario 3" {
                                selectedScenario = recompostionScenario3[index]
                            }

                        }

                        /////////
                        
                        var nutrients = [[String: Any]]()
                        
                        for value in selectedScenario {
                            
                            var calories = ""
                            var protein = ""
                            var carbs = ""
                            var fat = ""
                            
                            if value == "A" {
                                calories = String("\(ceil(self.aValues.calorie*100)/100)")
                                carbs = String("\(ceil(self.aValues.carbs*100)/100)")
                                protein = String("\(ceil(self.aValues.protein*100)/100)")
                                fat = String("\(ceil(self.aValues.fat*100)/100)")
                            } else if value == "B" {
                                calories = String("\(ceil(self.bValues.calorie*100)/100)")
                                carbs = String("\(ceil(self.bValues.carbs*100)/100)")
                                protein = String("\(ceil(self.bValues.protein*100)/100)")
                                fat = String("\(ceil(self.bValues.fat*100)/100)")
                            } else if value == "C" {
                                calories = String("\(ceil(self.cValues.calorie*100)/100)")
                                carbs = String("\(ceil(self.cValues.carbs*100)/100)")
                                protein = String("\(ceil(self.cValues.protein*100)/100)")
                                fat = String("\(ceil(self.cValues.fat*100)/100)")
                            } else if value == "A+" {
                                calories = String("\(ceil(self.aPlusValues.calorie*100)/100)")
                                carbs = String("\(ceil(self.aPlusValues.carbs*100)/100)")
                                protein = String("\(ceil(self.aPlusValues.protein*100)/100)")
                                fat = String("\(ceil(self.aPlusValues.fat*100)/100)")
                            }

                            let dict = [
                                "calorie": calories,
                                "carbs": carbs,
                                "protein": protein,
                                "fat": fat
                            ]
                            
                            nutrients.append(dict)
                        }
                        
                        
                        
                        let weekStartDate = Date.today().previous(.sunday)
                        let weekEndDate = Date.today().next(.saturday)

                        let dateFormatter = DateFormatter()
                        dateFormatter.dateFormat = "dd-MM-yyyy"

                        let weekStartDateStr = dateFormatter.string(from: weekStartDate)
                        let weekEndDateStr = dateFormatter.string(from: weekEndDate)

                        
                        let weekData = [
                            "baselineCalorie": baselineCalorie,
                            "baselineScenario": baselineScenario,
                            "checkedIn": false,
                            "goal": goal,
                            "goalScenario": goalScenario,
                            "feeling": "",
                            "macroRoutine": "",
                            "weekStartWeight": weekEndWeight,
                            "weekEndWeight": weekEndWeight,
                            "weekStartDate": weekStartDateStr,
                            "weekEndDate": weekEndDateStr,
                            "nutrients": nutrients
                            
                        ] as [String : Any]


                        FirebaseSession.shared.saveWeeklyData(userid: uid, weekPath: "Week \(weekProgress)", data: weekData)

                        
                        // Save Next Week Data & Update Macros Inputs Check In date
                        let nextSundayDate = Date.today().next(.sunday)
                        let nextSundayDateStr = dateFormatter.string(from: nextSundayDate)
                        self.updateMacroBaselineCalculations(uid: uid, data: ["weekInProgress": weekProgress, "nextCheckInDate": nextSundayDateStr])
                    }

                }
              } else {
                print("Document does not exist")
              }
          }
    }
    
    func updateWeeklyCalculations(uid: String, weekPath: String, data: [String: Any]) {
        self.db.collection("MacrosCalculation").document(uid).collection("WeeklyCheckIn").document(weekPath).updateData(data)
    }

    func updateMacroBaselineCalculations(uid: String, data: [String: Any]) {
        self.db.collection("MacrosCalculation").document(uid).updateData(data)
    }
    
    func getCheckInWeeklyCalculations(uid: String, weekPath: String, completion: @escaping ([String: Any]) -> Void) {
        self.db.collection("MacrosCalculation").document(uid).collection("WeeklyCheckIn").document(weekPath).getDocument { (snapshot, error) in
              if let document = snapshot, document.exists {
                if let documentData = document.data() {
                    completion(documentData)
                }
              } else {
                print("Document does not exist")
              }
          }
    }

    func calculateLoseWeightValues(baselineCalorie: Int) {
        var aValues: (calorie: Double, protein: Double, carbs: Double, fat: Double)
        var bValues: (calorie: Double, protein: Double, carbs: Double, fat: Double)
        var cValues: (calorie: Double, protein: Double, carbs: Double, fat: Double)
        var aPlusValues: (calorie: Double, protein: Double, carbs: Double, fat: Double)

        aValues.calorie = Double(baselineCalorie)
        aValues.protein = 0.4*aValues.calorie/4
        aValues.carbs = 0.3*aValues.calorie/4
        aValues.fat = 0.3*aValues.calorie/9

        bValues.calorie = aValues.calorie*0.9
        bValues.protein = aValues.protein*0.85
        bValues.carbs = aValues.carbs*0.85
        bValues.fat = aValues.fat*0.85

        cValues.calorie = bValues.calorie*0.9
        cValues.protein = bValues.protein*0.85
        cValues.carbs = bValues.carbs*0.85
        cValues.fat = bValues.fat*0.85

        aPlusValues.calorie = aValues.calorie*1.1
        aPlusValues.protein = aValues.protein*1.15
        aPlusValues.carbs = aValues.carbs*1.15
        aPlusValues.fat = aValues.fat*1.15

        print("A: ", aValues)
        print("B: ", bValues)
        print("C: ", cValues)
        print("A+: ", aPlusValues)
        
       // print(ceil(aPlusValues.carbs*100)/100)
        
        self.aValues = aValues
        self.bValues = bValues
        self.cValues = cValues
        self.aPlusValues = aPlusValues
    }
    
    func calculateRecompositionValues(baselineCalorie: Int) {
        var aValues: (calorie: Double, protein: Double, carbs: Double, fat: Double)
        var bValues: (calorie: Double, protein: Double, carbs: Double, fat: Double)
        var cValues: (calorie: Double, protein: Double, carbs: Double, fat: Double)
        var aPlusValues: (calorie: Double, protein: Double, carbs: Double, fat: Double)

        aValues.calorie = Double(baselineCalorie)
        aValues.protein = 0.35*aValues.calorie/4
        aValues.carbs = 0.35*aValues.calorie/4
        aValues.fat = 0.3*aValues.calorie/9

        bValues.calorie = aValues.calorie*0.9
        bValues.protein = aValues.protein*0.85
        bValues.carbs = aValues.carbs*0.85
        bValues.fat = aValues.fat*0.85

        cValues.calorie = bValues.calorie*0.9
        cValues.protein = bValues.protein*0.85
        cValues.carbs = bValues.carbs*0.85
        cValues.fat = bValues.fat*0.85

        aPlusValues.calorie = aValues.calorie*1.1
        aPlusValues.protein = aValues.protein*1.15
        aPlusValues.carbs = aValues.carbs*1.15
        aPlusValues.fat = aValues.fat*1.15

        print("A: ", aValues)
        print("B: ", bValues)
        print("C: ", cValues)
        print("A+: ", aPlusValues)
        
        self.aValues = aValues
        self.bValues = bValues
        self.cValues = cValues
        self.aPlusValues = aPlusValues
    }

    func calculateMaintainValues(baselineCalorie: Int) {
        var aValues: (calorie: Double, protein: Double, carbs: Double, fat: Double)
        var bValues: (calorie: Double, protein: Double, carbs: Double, fat: Double)
        var cValues: (calorie: Double, protein: Double, carbs: Double, fat: Double)
        var aPlusValues: (calorie: Double, protein: Double, carbs: Double, fat: Double)

        aValues.calorie = Double(baselineCalorie)
        aValues.protein = 0.3*aValues.calorie/4
        aValues.carbs = 0.4*aValues.calorie/4
        aValues.fat = 0.3*aValues.calorie/9

        bValues.calorie = aValues.calorie*0.95
        bValues.protein = bValues.calorie*0.3/4
        bValues.carbs = bValues.calorie*0.4/4
        bValues.fat = bValues.calorie*0.3/9

        cValues.calorie = bValues.calorie*0.9
        cValues.protein = cValues.calorie*0.3/4
        cValues.carbs = cValues.calorie*0.4/4
        cValues.fat = cValues.calorie*0.3/9

        aPlusValues.calorie = aValues.calorie*1.05
        aPlusValues.protein = aPlusValues.calorie*0.3/4
        aPlusValues.carbs = aPlusValues.calorie*0.4/4
        aPlusValues.fat = aPlusValues.calorie*0.3/9

        print("A: ", aValues)
        print("B: ", bValues)
        print("C: ", cValues)
        print("A+: ", aPlusValues)
        
        self.aValues = aValues
        self.bValues = bValues
        self.cValues = cValues
        self.aPlusValues = aPlusValues
    }
    
    func calculateGainValues(baselineCalorie: Int) {
        var aValues: (calorie: Double, protein: Double, carbs: Double, fat: Double)
        var bValues: (calorie: Double, protein: Double, carbs: Double, fat: Double)
        var cValues: (calorie: Double, protein: Double, carbs: Double, fat: Double)
        var aPlusValues: (calorie: Double, protein: Double, carbs: Double, fat: Double)

        aValues.calorie = Double(baselineCalorie)
        aValues.protein = 0.3*aValues.calorie/4
        aValues.carbs = 0.4*aValues.calorie/4
        aValues.fat = 0.3*aValues.calorie/9

        bValues.calorie = aValues.calorie*0.95
        bValues.protein = bValues.calorie*0.3/4
        bValues.carbs = bValues.calorie*0.4/4
        bValues.fat = bValues.calorie*0.3/9

        cValues.calorie = bValues.calorie*0.9
        cValues.protein = cValues.calorie*0.3/4
        cValues.carbs = cValues.calorie*0.4/4
        cValues.fat = cValues.calorie*0.3/9

        aPlusValues.calorie = aValues.calorie*1.15
        aPlusValues.protein = aPlusValues.calorie*0.3/4
        aPlusValues.carbs = aPlusValues.calorie*0.4/4
        aPlusValues.fat = aPlusValues.calorie*0.3/9

        print("A: ", aValues)
        print("B: ", bValues)
        print("C: ", cValues)
        print("A+: ", aPlusValues)
        
        self.aValues = aValues
        self.bValues = bValues
        self.cValues = cValues
        self.aPlusValues = aPlusValues
    }

    // MARK: Challenges
    
    func getUserSubscribedChallenges() {
        self.db.collection("Users").document(FirebaseSession.shared.session.uid).collection("SubscribedChallenges").addSnapshotListener(includeMetadataChanges: false) { (snapshot, error) in
            if let error = error {
                print("add Listner error: ", error.localizedDescription as Any)
            } else if let snapshot = snapshot {
                
                snapshot.documentChanges.forEach { diff in
                    if (diff.type == .added) {
                        print("New Task: \(diff.document.data())")
                        
                        var data = diff.document.data()
                        
                        data["documentId"] = diff.document.documentID

                        self.subscribedChallenges.append(data)
                         
                    }
                    if (diff.type == .modified) {
                        print("Modified Task: \(diff.document.data())")
                    }
                    if (diff.type == .removed) {
                        print("Removed Task: \(diff.document.data())")
                    }
                }
            }
        }
    }

    func getChallenges() {
        self.db.collection("challenges").addSnapshotListener(includeMetadataChanges: false) { (snapshot, error) in
            if let error = error {
                print("add Listner error: ", error.localizedDescription as Any)
            } else if let snapshot = snapshot {
//                print("add Listner snaphot: ", snapshot.documents)
                
                snapshot.documentChanges.forEach { diff in
                    if (diff.type == .added) {
                        print("New Task: \(diff.document.data())")
                        
                        var data = diff.document.data()
                        data["documentId"] = diff.document.documentID
                        self.challengesArray.append(data)
                         
                    }
                    if (diff.type == .modified) {
                        print("Modified Task: \(diff.document.data())")
                        
                        FirebaseSession.shared.challengesArray = FirebaseSession.shared.challengesArray.map({
                            var dict = $0
                            if dict["userid"] as? String == diff.document.documentID {
                                var data = diff.document.data()
                                data["documentId"] = diff.document.documentID
                                dict = data
                            }
                            return dict
                        })
                    }
                    if (diff.type == .removed) {
                        print("Removed Task: \(diff.document.data())")
                    }
                }
            }
        }
    }
    
    func updateChallenges(documentid: String, data: [String: Any]) {
        self.db.collection("challenges").document(documentid).updateData(data)
    }
    
    func joinChallengeData(documentid: String, userid: String, data: [String: Any]) {
        // Add a new document with a generated ID
        
        self.db.collection("challenges").document(documentid).collection("JoinedUsers").document(userid).setData(data, completion: { (error) in
            print("Error adding document: \(String(describing: error))")
        })
    }
    
    func addChallengesInUser(challengeId: String, userid: String, data: [String: Any]) {
        // Add a new document with a generated ID
        
        self.db.collection("Users").document(userid).collection("SubscribedChallenges").document(challengeId).setData(data, completion: { (error) in
            print("Error adding document: \(String(describing: error))")
        })
    }

    func challengeCheckIn(challengeId: String, userid: String, data: [String: Any]) {
        // Add a new document with a generated ID
        
        self.db.collection("Users").document(userid).collection("ChallengeCheckedIn").addDocument(data: data)
    }
    
    func getChallengesCheckedIn() {
        self.db.collection("Users").document(FirebaseSession.shared.session.uid).collection("ChallengeCheckedIn").addSnapshotListener(includeMetadataChanges: false) { (snapshot, error) in
            if let error = error {
                print("add Listner error: ", error.localizedDescription as Any)
            } else if let snapshot = snapshot {
//                print("add Listner snaphot: ", snapshot.documents)
                
                snapshot.documentChanges.forEach { diff in
                    if (diff.type == .added) {
                        print("New Task: \(diff.document.data())")
                        
                        var data = diff.document.data()
                        data["documentId"] = diff.document.documentID
                        self.challengesCheckedInArray.append(data)
                         
                    }
                    if (diff.type == .modified) {
                        print("Modified Task: \(diff.document.data())")
                    }
                    if (diff.type == .removed) {
                        print("Removed Task: \(diff.document.data())")
                    }
                }
            }
        }
    }

    func getThundrbroMeals() {
        self.db.collection("meals").addSnapshotListener(includeMetadataChanges: false) { (snapshot, error) in
            if let error = error {
                print("add Listner error: ", error.localizedDescription as Any)
            } else if let snapshot = snapshot {
//                print("add Listner snaphot: ", snapshot.documents)
                
                snapshot.documentChanges.forEach { diff in
                    if (diff.type == .added) {
                        print("New Task: \(diff.document.data())")
                        
                        var data = diff.document.data()
                        data["documentId"] = diff.document.documentID
                        
                        let weekRange = data["weekRange"] as? String ?? ""
                        let splitArray = weekRange.components(separatedBy: " - ")
                        if splitArray.count == 2 {
                            let weekStartDateStr = splitArray[0]
                            let weekEndDateStr = splitArray[1]
                            
                            let dateFormatter = DateFormatter()
                            dateFormatter.dateFormat = "yyyy-MM-dd"
                            dateFormatter.timeZone = TimeZone(abbreviation: "UTC")

                            let weekStartDate = dateFormatter.date(from: weekStartDateStr)
                            let weekEndDate = dateFormatter.date(from: weekEndDateStr)
                            
                            data["weekStartDate"] = weekStartDate
                            data["weekEndDate"] = weekEndDate
                        }

                        self.thundrMeals.append(data)
                         
                    }
                    if (diff.type == .modified) {
                        print("Modified Task: \(diff.document.data())")
                    }
                    if (diff.type == .removed) {
                        print("Removed Task: \(diff.document.data())")
                    }
                }
            }
        }
    }

    func getShoppingList() {
        self.db.collection("shoppingList").addSnapshotListener(includeMetadataChanges: false) { (snapshot, error) in
            if let error = error {
                print("add Listner error: ", error.localizedDescription as Any)
            } else if let snapshot = snapshot {
//                print("add Listner snaphot: ", snapshot.documents)
                
                snapshot.documentChanges.forEach { diff in
                    if (diff.type == .added) {
                        print("New Task: \(diff.document.data())")
                        
                        var data = diff.document.data()
                        data["documentId"] = diff.document.documentID
                        
                        let weekRange = data["weekRange"] as? String ?? ""
                        let splitArray = weekRange.components(separatedBy: " - ")
                        if splitArray.count == 2 {
                            let weekStartDateStr = splitArray[0]
                            let weekEndDateStr = splitArray[1]
                            
                            let dateFormatter = DateFormatter()
                            dateFormatter.dateFormat = "MM-dd-yyyy"
                            dateFormatter.timeZone = TimeZone(abbreviation: "UTC")

                            let weekStartDate = dateFormatter.date(from: weekStartDateStr)
                            let weekEndDate = dateFormatter.date(from: weekEndDateStr)
                            
                            data["weekStartDate"] = weekStartDate
                            data["weekEndDate"] = weekEndDate
                        }

                        self.shoppingList.append(data)
                         
                    }
                    if (diff.type == .modified) {
                        print("Modified Task: \(diff.document.data())")
                    }
                    if (diff.type == .removed) {
                        print("Removed Task: \(diff.document.data())")
                    }
                }
            }
        }
    }

    func shoppingCheckIn(shoppingId: String, userid: String, data: [String: Any], completion: @escaping (Bool) -> Void) {
        // Add a new document with a generated ID
        self.db.collection("Users").document(userid).collection("ShoppingCheckedIn").document(shoppingId).setData(data, completion: { (error) in
            completion(true)
        })
    }

    func deleteShoppingCheckIn(shoppingId: String, userid: String, completion: @escaping (Bool) -> Void) {
        // Add a new document with a generated ID
        self.db.collection("Users").document(userid).collection("ShoppingCheckedIn").document(shoppingId).delete { (error) in
            completion(true)
        }
    }
    
    func saveMeals(mealId: String, userid: String, data: [String: Any], completion: @escaping (Bool) -> Void) {
        // Add a new document with a generated ID
        self.db.collection("Users").document(userid).collection("SavedMeals").document(mealId).setData(data, completion: { (error) in
            completion(true)
        })
        
    }

    func deleteMeal(mealId: String, userid: String, completion: @escaping (Bool) -> Void) {
        self.db.collection("Users").document(userid).collection("SavedMeals").document(mealId).delete { (error) in
            completion(true)
        }
    }

    func getShoppingCheckedIn() {
        self.db.collection("Users").document(FirebaseSession.shared.session.uid).collection("ShoppingCheckedIn").addSnapshotListener(includeMetadataChanges: false) { (snapshot, error) in
            if let error = error {
                print("add Listner error: ", error.localizedDescription as Any)
            } else if let snapshot = snapshot {
                
                snapshot.documentChanges.forEach { diff in
                    if (diff.type == .added) {
                        print("New Task: \(diff.document.data())")
                        
                        var data = diff.document.data()
                        data["documentId"] = diff.document.documentID
                        self.checkedInShoppingList.append(data)
                         
                    }
                    if (diff.type == .modified) {
                        print("Modified Task: \(diff.document.data())")
                        
                        FirebaseSession.shared.checkedInShoppingList = FirebaseSession.shared.checkedInShoppingList.map({
                            var dict = $0
                            if dict["shoppingId"] as? String == diff.document.documentID {
                                var data = diff.document.data()
                                data["documentId"] = diff.document.documentID
                                dict = data
                            }
                            return dict
                        })

                    }
                    if (diff.type == .removed) {
                        print("Removed Task: \(diff.document.data())")
                    }
                }
            }
        }
    }

    func getSavedMeals() {
        self.db.collection("Users").document(FirebaseSession.shared.session.uid).collection("SavedMeals").addSnapshotListener(includeMetadataChanges: false) { (snapshot, error) in
            if let error = error {
                print("add Listner error: ", error.localizedDescription as Any)
            } else if let snapshot = snapshot {
                
                snapshot.documentChanges.forEach { diff in
                    if (diff.type == .added) {
                        print("New Task: \(diff.document.data())")
                        
                        var data = diff.document.data()
                        data["documentId"] = diff.document.documentID
                        self.savedMeals.append(data)
                         
                    }
                    if (diff.type == .modified) {
                        print("Modified Task: \(diff.document.data())")
                        
                        FirebaseSession.shared.savedMeals = FirebaseSession.shared.savedMeals.map({
                            var dict = $0
                            if dict["shoppingId"] as? String == diff.document.documentID {
                                var data = diff.document.data()
                                data["documentId"] = diff.document.documentID
                                dict = data
                            }
                            return dict
                        })

                    }
                    if (diff.type == .removed) {
                        print("Removed Task: \(diff.document.data())")
                    }
                }
            }
        }
    }

}
