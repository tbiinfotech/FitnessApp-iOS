//
//  NotificationsViewController.swift
//  Fitness F Thundr
//
//  Created by Satinderjeet Pawar on 20/09/21.
//

import UIKit
import Firebase

class NotificationsViewController: UIViewController {

    @IBOutlet weak var notificationTbl: UITableView!

    var notificationArray = [[String: Any]]()
    var user = [[String: Any]]()

    var db : Firestore!

    override func viewDidLoad() {
        super.viewDidLoad()

        db = Firestore.firestore()
        getNotifications()
    }
    
    func getNotifications() {
        self.db.collection("Notifications").document(UserDefaults.standard.getUserUiD()).collection("notifications").order(by: "notif_time", descending: true).addSnapshotListener { [self] (snapshot, error) in
            if let error = error {
                print(error)
            } else if let snapshot = snapshot {
                notificationArray.removeAll()
                self.user.removeAll()
                for document in snapshot.documents {
                    let dict = document.data()

                    self.db.collection("Users").document(dict["user_id"] as? String ?? "").getDocument(completion: { (snapshot, err) in
                        if let err = err {
                            print("Error getting documents: \(err)")
                        } else {
                            self.user.append((snapshot?.data())!)
                            notificationArray.append(dict)

                            notificationArray.sort(by: { $0["notif_time"] as? Int ?? 0 > $1["notif_time"] as? Int ?? 0 })
                            self.notificationTbl.reloadData()
                            
                        }
                  })
                }
            }
        }
    }


    @IBAction func actionBack(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }

}

//MARK: TABLEVIEWDATASORUCE & DELEGATE

extension NotificationsViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.notificationArray.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "NotificationsCell") as! NotificationsCell

        cell.notificationImgView.sd_setImage(with: URL(string: self.user[indexPath.row]["photo"] as? String ?? ""), placeholderImage: UIImage(named: "user-placeholder"))
        cell.nameLbl.text = self.user[indexPath.row]["username"] as? String ?? ""

        cell.acceptBtn.isHidden = true
        cell.declineBtn.isHidden = true
        cell.addFriendImgView.isHidden = true
        
        cell.acceptBtn.tag = indexPath.row
        cell.declineBtn.tag = indexPath.row
        
        cell.acceptBtn.addTarget(self, action: #selector(acceptAction(_:)), for: .touchUpInside)
        cell.declineBtn.addTarget(self, action: #selector(declineAction(_:)), for: .touchUpInside)

        let notificationType = notificationArray[indexPath.row]["notif_type"] as? String ?? ""
        
        switch notificationType {
        case "friend_rq":
            
            if let status = notificationArray[indexPath.row]["req_accepted_or_decline"] as? Bool, status == false {
                cell.acceptBtn.isHidden = false
                cell.declineBtn.isHidden = false
                cell.addFriendImgView.isHidden = false
            }
            
            cell.titleLbl.text = "sent you a friend request"

            break
        case "reply_to_post":
            cell.titleLbl.text = "replied to your post: \(notificationArray[indexPath.row]["notif_content"] as? String ?? "")"
            break
        case "like_post":
            cell.titleLbl.text = "liked your post"
            break
        default: break
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 80
    }
    
    @objc func acceptAction(_ sender: UIButton) {
        let id = notificationArray[sender.tag]["id"] as? String ?? ""
        let otherUserId = notificationArray[sender.tag]["user_id"] as? String ?? ""
        let userId = UserDefaults.standard.getUserUiD()

        self.db.collection("Notifications").document(UserDefaults.standard.getUserUiD()).collection("notifications").document(id).updateData(["req_accepted_or_decline": true, "seen": true])
        
        self.db.collection("Friend_req").document(otherUserId).collection("requests").document(userId).delete()
        self.db.collection("Friend_req").document(userId).collection("requests").document(otherUserId).delete()
        
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd-MMM-yyyy h:mm:ss a"
        
        let dict = ["date": dateFormatter.string(from: Date())]

        
        self.db.collection("Friends").document(userId).collection("friends").document(otherUserId).setData(dict)
        self.db.collection("Friends").document(otherUserId).collection("friends").document(userId).setData(dict)

    }

    @objc func declineAction(_ sender: UIButton) {        
        let id = notificationArray[sender.tag]["id"] as? String ?? ""
        let otherUserId = notificationArray[sender.tag]["user_id"] as? String ?? ""

        
        self.db.collection("Notifications").document(UserDefaults.standard.getUserUiD()).collection("notifications").document(id).updateData(["req_accepted_or_decline": true, "seen": true])
        
        self.db.collection("Friend_req").document(otherUserId).collection("requests").document(UserDefaults.standard.getUserUiD()).delete()
        self.db.collection("Friend_req").document(UserDefaults.standard.getUserUiD()).collection("requests").document(otherUserId).delete()

    }

}
