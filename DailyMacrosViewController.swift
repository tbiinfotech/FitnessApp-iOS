//
//  DailyMacrosViewController.swift
//  Fitness F Thundr
//
//  Created by Satinderjeet Pawar on 30/11/21.
//

import UIKit

class DailyMacrosViewController: UIViewController {

    
    @IBOutlet weak var caloriesLbl: UILabel!
    @IBOutlet weak var proteinLbl: UILabel!
    @IBOutlet weak var carbsLbl: UILabel!
    @IBOutlet weak var fatLbl: UILabel!

    @IBOutlet weak var breakdownSwitch: UISwitch!

    let recommendedMacros = UINib(nibName:"RecommendedMacros",bundle:.main).instantiate(withOwner: nil, options: nil).first as! RecommendedMacros

    override func viewDidLoad() {
        super.viewDidLoad()

        recommendedMacros.btnCross.addTarget(self, action: #selector(actionCross(_:)), for:.touchUpInside)
        recommendedMacros.calculateBtn.addTarget(self, action: #selector(CalculateAction(_:)), for: .touchUpInside)
        recommendedMacros.learnBtn.addTarget(self, action: #selector(LearnMacrosAction(_:)), for: .touchUpInside)

        
        self.navigationController?.isNavigationBarHidden = true
                
        let weekday = Calendar.current.component(.weekday, from: Date())
        print(weekday)
        
        if let nutrients = FirebaseSession.shared.currentWeekMacrosData["nutrients"] as? [[String: Any]] {
            let nutrient = nutrients[weekday - 1]
            caloriesLbl.text = nutrient["calorie"] as? String ?? ""
            proteinLbl.text = nutrient["protein"] as? String ?? ""
            carbsLbl.text = nutrient["carbs"] as? String ?? ""
            fatLbl.text = nutrient["fat"] as? String ?? ""
        }
    }
    
    //MARK: ACTIONS
    
    @objc func CalculateAction(_ sender: UIButton) {
        let nextVc = self.storyboard?.instantiateViewController(identifier: macroCalculatorGoalsViewController) as! MacroCalculatorGoalsViewController
        self.navigationController?.pushViewController(nextVc, animated: true)
        self.recommendedMacros.removeFromSuperview()
    }

    @objc func LearnMacrosAction(_ sender: UIButton) {
        let nextVc = self.storyboard?.instantiateViewController(identifier: "LearnMacrosViewController") as! LearnMacrosViewController
        self.navigationController?.pushViewController(nextVc, animated: true)
        self.recommendedMacros.removeFromSuperview()
    }

    @objc func actionCross(_ sender : UIButton) {
        self.recommendedMacros.removeFromSuperview()
    }

    
    @IBAction func CloseAction(_ sender: UIButton) {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func BreakdownAction(_ sender: UISwitch) {
        
        var calories =  Double(caloriesLbl.text!) ?? 0.0
        var carbs =  Double(carbsLbl.text!) ?? 0.0
        var protein =  Double(proteinLbl.text!) ?? 0.0
        var fat =  Double(fatLbl.text!) ?? 0.0

        
        if sender.isOn {
            calories = calories / 7.716179
            carbs = carbs / 7.716179
            protein = protein / 7.716179
            fat = fat / 7.716179
            
        } else {
            calories = calories * 7.716179
            carbs = carbs * 7.716179
            protein = protein * 7.716179
            fat = fat * 7.716179
        }
        
        caloriesLbl.text = String("\(ceil(calories*100)/100)")
        carbsLbl.text = String("\(ceil(carbs*100)/100)")
        proteinLbl.text = String("\(ceil(protein*100)/100)")
        fatLbl.text = String("\(ceil(fat*100)/100)")

    }
    
    @IBAction func RecalculateAction(_ sender: UIButton) {
        
        recommendedMacros.frame = self.view.bounds
        self.view.addSubview(recommendedMacros)
        
        

    }

}
