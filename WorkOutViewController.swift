//
//  WorkOutViewController.swift
//  Fitness F Thundr
//
//  Created by Macbook Pro on 13/05/21.
//

import UIKit
import SideMenu
import Firebase
import FirebaseAuth
import FirebaseDatabase
import FirebaseFirestore

class WorkOutViewController: UIViewController {
    
    @IBOutlet weak var workoutsTableView: UITableView!
    @IBOutlet weak var workoutAllCollectionView: UICollectionView!
    @IBOutlet weak var searchTbl: UITableView!
    @IBOutlet weak var searchTxtField: UITextField!
    @IBOutlet weak var searchTblHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var backBtn: UIButton!

    var db : Firestore!
    var workoutArr = [[String: Any]]()
    var allWorkouts = [[String: Any]]()

    var workoutCategoriesArr = [[String: Any]]()
    var subscribedWorkouts = [[String: Any]]()

    var bookmarkedWorkouts = [[String: Any]]()
    var workoutForDayArray = [[String: Any]]()

    var allChallenges = [[String: Any]]()
    var filteredChallengesWorkouts = [[String: Any]]()

    var selectedCategoryIndex = 0

    var isFromHome = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
   
        if isFromHome {
            backBtn.isHidden = false
        } else {
            backBtn.isHidden = true
        }
  
        self.getWorkoutCategories()
        self.getWorkout()
        self.getSubscribedWorked()
        self.getBookmarkedWorkouts()
        getAllChallenges()
    }
    
    
    func getWorkoutCategories() {
        db = Firestore.firestore()
        db.collection("WorkoutCategories").addSnapshotListener() { (snapshot, err) in
            if let err = err {
                print("Error getting documents: \(err)")
            } else {
                self.workoutCategoriesArr.removeAll()
                self.workoutCategoriesArr.insert(["categoryName":"All"], at: 0)
                for document in snapshot!.documents {
                    self.workoutCategoriesArr.append(document.data())
                    self.workoutAllCollectionView.reloadData()
                }
            }
        }
    }

    func getBookmarkedWorkouts() {
        db = Firestore.firestore()
        db.collection("Users").document(UserDefaults.standard.getUserUiD()).collection("BookmarkedWorkouts").addSnapshotListener() { (snapshot, err) in
                if let err = err {
                    print("Error getting documents: \(err)")
                } else {
                    self.bookmarkedWorkouts.removeAll()
                  for document in snapshot!.documents {
                    self.bookmarkedWorkouts.append(document.data())
                    self.workoutAllCollectionView.reloadData()
                  }
                  
                }
          }
    }
    
    func getWorkout() {
        db.collection("Workouts").addSnapshotListener() { (snapshot, err) in
            if let err = err {
                print("Error getting documents: \(err)")
            } else {
                self.workoutArr.removeAll()
                
                self.allWorkouts.removeAll()
                self.workoutForDayArray.removeAll()
                
                for document in snapshot!.documents {
                    
                    var data = document.data()
                    data["documentId"] = document.documentID

                   ]
                    self.workoutArr.append(data)
                    self.allWorkouts.append(data)
                    
                    let dateFormatter = DateFormatter()
                    dateFormatter.dateFormat = "yyyy-MM-dd"

                    let currentDate = dateFormatter.string(from: Date())
                    
                    if let workoutOfDay = data["workoutOfTheDayDate"] as? String, workoutOfDay == currentDate {
                        self.workoutForDayArray.append(data)
                    }
                    
                    self.workoutsTableView.reloadData()
                  }
            }
        }
    }
    
    func getSubscribedWorked() {
        db.collection("Users").document(UserDefaults.standard.getUserUiD()).collection("SubscribedWorkouts").addSnapshotListener() { (snapshot, err) in
                if let err = err {
                    print("Error getting d ocuments: \(err)")
                } else {
                    self.subscribedWorkouts.removeAll()
                  for document in snapshot!.documents {
                    self.subscribedWorkouts.append(document.data())
                    self.workoutsTableView.reloadData()
                  }
                }
          }
    }
    
    func getAllChallenges() {

        db = Firestore.firestore()
        db.collection("challenges").addSnapshotListener() { [self] (snapshot, err) in
            if let err = err {
                print("Error getting documents: \(err)")
            } else {
                    
                allChallenges.removeAll()
                    
                for document in snapshot!.documents {
                    var data = document.data()
                    data["documentId"] = document.documentID
                    allChallenges.append(data)
                }
            }
        }
    }

    
    
    //MARK: ACTIONS
    
    
    @IBAction func actionBack(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }
    
    @IBAction func CalendarAction(_ sender: Any) {
        _ = self.tabBarController?.selectedIndex = 3
    }
    
    @IBAction func TrimAction(_ sender: Any) {
        
        let filterWorkouts = workoutForDayArray.filter { $0["workoutGoal"] as? String == "trim" }
        
        if filterWorkouts.count > 0 {
            
            var isBookmarked = false
            let filterBookmarks = bookmarkedWorkouts.filter { $0["id"] as? String == filterWorkouts[0]["documentId"] as? String }
            if filterBookmarks.count > 0 {
                isBookmarked = true
            }
            
            let nextVc = self.storyboard?.instantiateViewController(withIdentifier: workoutFeorceFitnessViewController) as! WorkoutFeorceFitnessViewController
            nextVc.workoutDict = filterWorkouts[0]
            nextVc.isBookmarked = isBookmarked
            self.navigationController?.pushViewController(nextVc, animated: true)
        } else {
            Alert.showSimple("No workout found!")
        }

    }
    
    @IBAction func SculptAction(_ sender: Any) {
        
        let filterWorkouts = workoutForDayArray.filter { $0["workoutGoal"] as? String == "sculpt" }
        
        if filterWorkouts.count > 0 {
            
            var isBookmarked = false
            let filterBookmarks = bookmarkedWorkouts.filter { $0["id"] as? String == filterWorkouts[0]["documentId"] as? String }
            if filterBookmarks.count > 0 {
                isBookmarked = true
            }
            
            let nextVc = self.storyboard?.instantiateViewController(withIdentifier: workoutFeorceFitnessViewController) as! WorkoutFeorceFitnessViewController
            nextVc.workoutDict = filterWorkouts[0]
            nextVc.isBookmarked = isBookmarked
            self.navigationController?.pushViewController(nextVc, animated: true)
        } else {
            Alert.showSimple("No workout found!")
        }

    }
    
    @IBAction func BuildAction(_ sender: Any) {
        
        let filterWorkouts = workoutForDayArray.filter { $0["workoutGoal"] as? String == "build" }
        
        if filterWorkouts.count > 0 {
            
            var isBookmarked = false
            let filterBookmarks = bookmarkedWorkouts.filter { $0["id"] as? String == filterWorkouts[0]["documentId"] as? String }
            if filterBookmarks.count > 0 {
                isBookmarked = true
            }
            
            let nextVc = self.storyboard?.instantiateViewController(withIdentifier: workoutFeorceFitnessViewController) as! WorkoutFeorceFitnessViewController
            nextVc.workoutDict = filterWorkouts[0]
            nextVc.isBookmarked = isBookmarked
            self.navigationController?.pushViewController(nextVc, animated: true)
        } else {
            Alert.showSimple("No workout found!")
        }

    }
    
    @IBAction func actionMenu(_ sender: Any) {
        let menu = storyboard!.instantiateViewController(withIdentifier: "SideMenuNavigationController") as! SideMenuNavigationController
        present(menu, animated: true, completion: nil)
    }
    
    @IBAction func BookmarkAction(_ sender: Any) {
        let nextVc = self.storyboard!.instantiateViewController(identifier: "BookmarkWorkoutsViewController") as! BookmarkWorkoutsViewController
        nextVc.bookmark = "workout"
        self.navigationController!.pushViewController(nextVc, animated: true)
    }

}

//MARK: TABLEVIEWDATASOURCE&DELEGATE

extension WorkOutViewController: UITableViewDelegate,UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        if tableView == searchTbl {
            return 1
        }
//        return 2
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if tableView == searchTbl {
            return filteredChallengesWorkouts.count
        }
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        if tableView == searchTbl {
            let cell = tableView.dequeueReusableCell(withIdentifier: "SearchChallengeCell") as! SearchChallengeCell
            if let name = filteredChallengesWorkouts[indexPath.row]["challengeName"] as? String {
                cell.nameLbl.text = name
                cell.imgView?.sd_setImage(with: URL(string: filteredChallengesWorkouts[indexPath.row]["challengeBannerImage"] as? String ?? ""), placeholderImage: #imageLiteral(resourceName: "Screen Shot 2021-04-01 at 11.42 1"))
            } else if let name = filteredChallengesWorkouts[indexPath.row]["workoutName"] as? String {
                cell.nameLbl.text = name
                cell.imgView?.sd_setImage(with: URL(string: filteredChallengesWorkouts[indexPath.row]["workoutBannerImage"] as? String ?? ""), placeholderImage: #imageLiteral(resourceName: "Screen Shot 2021-04-01 at 11.42 1"))
            }
            return cell
        }

        if indexPath.section == 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: workoutOfTheDayTableViewCell) as! WorkoutOfTheDayTableViewCell
            cell.viewGradient.isHidden = false
            
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "MMM. dd"
            
            cell.workoutOfDayLbl.text = "Workout of \(dateFormatter.string(from: Date()))"

            
            return cell
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: workoutExploreOthersTableViewCell) as! WorkoutExploreOthersTableViewCell
            cell.workoutArr = self.workoutArr
            cell.subscribedWorkouts = subscribedWorkouts
            cell.workoutExploreOtherCollectionView.reloadData()
            cell.delegateWorkOutViewController = self
            cell.bookmarkedWorkouts = bookmarkedWorkouts
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if tableView == searchTbl {
            if let _ = filteredChallengesWorkouts[indexPath.row]["challengeName"] as? String {
           
                let documnetId = self.filteredChallengesWorkouts[indexPath.row]["documentId"] as? String ?? ""
                let challenge  = self.filteredChallengesWorkouts[indexPath.row]
                let nextVc = self.storyboard!.instantiateViewController(identifier: workoutChallengeViewController) as! WorkoutChallengeViewController
                nextVc.challengeDict = challenge
                nextVc.documentId = documnetId
                self.navigationController!.pushViewController(nextVc, animated: true)

            } else if let _ = filteredChallengesWorkouts[indexPath.row]["workoutName"] as? String {
                
                var isBookmarked = false
                let filterBookmarks = bookmarkedWorkouts.filter { $0["id"] as? String == self.filteredChallengesWorkouts[indexPath.row]["documentId"] as? String }
                if filterBookmarks.count > 0 {
                    isBookmarked = true
                }

                
                let nextVc = self.storyboard?.instantiateViewController(withIdentifier: workoutFeorceFitnessViewController) as! WorkoutFeorceFitnessViewController
                nextVc.workoutDict = self.filteredChallengesWorkouts[indexPath.row]
                nextVc.isBookmarked = isBookmarked
                self.navigationController?.pushViewController(nextVc, animated: true)
            }

            return
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if tableView == searchTbl {
            return UITableView.automaticDimension
        }
        if indexPath.section == 0 {
            return 727
        }
        return 242
    }
}


extension WorkOutViewController: UICollectionViewDelegate, UICollectionViewDataSource {
 
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.workoutCategoriesArr.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: workoutsAllCollectionViewCell, for: indexPath) as! WorkoutsAllCollectionViewCell
        cell.lblName.text = self.workoutCategoriesArr[indexPath.row]["categoryName"] as? String
       
        if indexPath.row == selectedCategoryIndex {
            cell.customDesign.backgroundColor = #colorLiteral(red: 0.7215686275, green: 0.6549019608, blue: 0.9254901961, alpha: 1)
            cell.lblName.textColor = #colorLiteral(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
        } else {
            cell.customDesign.backgroundColor = #colorLiteral(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0).withAlphaComponent(0.6)
            cell.lblName.textColor = #colorLiteral(red: 0.1921568627, green: 0.1176470588, blue: 0.4196078431, alpha: 1)
        }
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        selectedCategoryIndex = indexPath.row
        if indexPath.row == 0 {
            workoutArr = allWorkouts
        } else {
            workoutArr = allWorkouts.filter { $0["workoutType"] as? String == workoutCategoriesArr[indexPath.row]["categoryName"] as? String }
        }
        workoutAllCollectionView.reloadData()
        workoutsTableView.reloadData()
    }
}

extension WorkOutViewController: UITextFieldDelegate {
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let newString = NSString(string: textField.text ?? "").replacingCharacters(in: range, with: string)

        let challenges = allChallenges.filter { ($0["challengeName"] as? String ?? "").lowercased().contains(newString.lowercased()) }
        let workouts = allWorkouts.filter { ($0["workoutName"] as? String ?? "").lowercased().contains(newString.lowercased()) }

        filteredChallengesWorkouts = challenges + workouts
        
        searchTblHeightConstraint.constant = CGFloat(filteredChallengesWorkouts.count > 5 ? 71*5 : 71*(filteredChallengesWorkouts.count))
                    
        searchTbl.isHidden = filteredChallengesWorkouts.count == 0 ? true : false
        searchTbl.reloadData()

        return true
    }

    func textFieldShouldClear(_ textField: UITextField) -> Bool {
        searchTbl.isHidden = true
        return true
    }
}
