//
//  NewChatViewController.swift
//  Fitness F Thundr
//
//  Created by Macbook Pro on 25/05/21.
//

import UIKit
import Firebase
import FirebaseAuth
import FirebaseDatabase
import FirebaseFirestore
import SDWebImage


class NewChatViewController: UIViewController {

    @IBOutlet weak var viewGradient: UIView!
    @IBOutlet weak var newChatTableView: UITableView!
    
    var db : Firestore!
    var userListArr = [[String: Any]]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        hitViewDid()
    }
    
    func hitViewDid() {
        self.viewGradient.layer.configureGradientBackground(#colorLiteral(red: 0.07843137255, green: 0.03137254902, blue: 0.2117647059, alpha: 1),#colorLiteral(red: 0, green: 0, blue: 0, alpha: 1))
        getAllUsersList()
    }
    
    func getAllUsersList() {
        db = Firestore.firestore()
        db.collection("Users").addSnapshotListener(){ (snapshot, err) in
            if let err = err {
                print("Error getting documents: \(err)")
            } else {
                for document in snapshot!.documents {
                    print(document.data())
                    
                    let documentId = document.documentID
                    
                    if documentId != UserDefaults.standard.getUserUiD() {
                        var dict = document.data()
                        dict["id"] = documentId
                        self.userListArr.append(dict)
                    }
                    
                    self.newChatTableView.reloadData()
                }
               
            }
        }
    }
    
    //MARK:ACTIONS
    
    @IBAction func actionBack(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }
    
    @IBAction func actionProfile(_ sender: Any) {
    }
    
    @IBAction func actionMessageBoard(_ sender: Any) {
        let nextVc = self.storyboard?.instantiateViewController(identifier: addFriendViewController)as! AddFriendViewController
        self.navigationController?.pushViewController(nextVc, animated: true)
    }
    
}

//MARK: TABLEVIEWDATASOURCE&DELEGATE

extension NewChatViewController: UITableViewDelegate,UITableViewDataSource{
   
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return userListArr.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: newChatTableViewCell)as! NewChatTableViewCell
        cell.userListArr = self.userListArr
        cell.configure(index: indexPath.row)
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let nextVc = self.storyboard?.instantiateViewController(withIdentifier: chatViewController) as! ChatViewController
        nextVc.documentId = userListArr[indexPath.row]["id"] as? String ?? ""
        nextVc.userDict = userListArr[indexPath.row]
        self.navigationController?.pushViewController(nextVc, animated: true)

    }
}
