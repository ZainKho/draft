//
//  NewTripViewController.swift
//  Draft
//
//  Created by Olivia on 12/5/19.
//

import UIKit

class NewTripViewController: UIViewController {
    
    var trip: Trip
    var tableView: UITableView!
    var buttonFooterView: ButtonFooterView!
    var cells: [[InputCell]]!
    
    var tripName: String
    var location: String
    
    var reloadDelegate: ReloadTripDelegate!
    var emptyStateDelegate: EmptyStateDelegate!
    
    let inputReuseIdentifier = "inputCellReuseIdentifiers"
    let buttonReuseIdentifier = "buttonCellReuseIdentifiers"
    
    let CELL_HEIGHT: CGFloat = 48
    let HEADER_LABEL_HEIGHT: CGFloat = 68
    let BUTTON_FOOTER_HEIGHT: CGFloat = 98
    
    init(trip: Trip, title: String) {
        self.trip = trip
        self.tripName = trip.name
        self.location = trip.location
        super.init(nibName: nil, bundle: nil)
        self.title = title
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .CREAM
        
        // Navigation Bar
        navigationController?.navigationBar.barTintColor = .CLOUD
        
        // Appearance
        title = self.title
        
        navigationController?.navigationBar.titleTextAttributes = labelAttrs
        // Cancel button
        let cancelButton = UIBarButtonItem(title: "Cancel", style: .plain, target: self, action: #selector(cancelPressed))
        cancelButton.tintColor = .SPACE
        navigationItem.leftBarButtonItem = cancelButton
        // Add button
        let addButton = UIBarButtonItem(title: "Add", style: .done, target: self, action: #selector(donePressed))
        addButton.tintColor = .SPACE
        navigationItem.rightBarButtonItem = addButton
        
        cells = createCellsFromTrip(trip: self.trip)
        
        // Set up tableView
        tableView = UITableView(frame: CGRect(x: 0, y: 0, width: view.frame.width, height: view.frame.height), style: .grouped)
        tableView.backgroundColor = .CREAM
        tableView.separatorColor = .RAIN
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(InputTableViewCell.self, forCellReuseIdentifier: inputReuseIdentifier)
        tableView.register(ButtonTableViewCell.self, forCellReuseIdentifier: buttonReuseIdentifier)
        buttonFooterView = ButtonFooterView(frame: CGRect(x: 0, y: 0, width: view.frame.width, height: BUTTON_FOOTER_HEIGHT))
        buttonFooterView.addDayDelegate = self
        tableView.tableFooterView = buttonFooterView
        view.addSubview(tableView)
        setupConstraints()
    }
    
    func setupConstraints() {
        tableView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
    }
    
    @objc func cancelPressed() {
        dismiss(animated: true)
    }
    
    @objc func donePressed() {
        emptyStateDelegate.dismissEmptyState()
        
        let userDefaults = UserDefaults.standard
        if let userID = userDefaults.value(forKey: "user") as? Int {
            Networking.shared.createTrip(userID: userID, name: trip.name, start: trip.len, location: trip.location, entries: daysToEntries(days: trip.days)) { (trip) in
                self.trip.id = trip.id
                self.reloadDelegate.reloadTrips(trip: convertBackendTrip(trip: trip))
                self.dismiss(animated: true)
            }
        }

    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc func dismissViewController() {
        dismiss(animated: true, completion: nil)
    }
    
    func createCellsFromTrip(trip: Trip) -> [[InputCell]] {
        var inputCells = [[InputCell]]()
        let days = trip.days
        for day in days {
            var dayArray = [InputCell]()
            for a in day.attractions {
                dayArray.append(InputCell(text: a, type: .ainput))
            }
            dayArray.append(InputCell(text: "+ Add Attraction", type: .aButton))
            for r in day.restaurants {
                dayArray.append(InputCell(text: r, type: .rinput))
            }
            dayArray.append(InputCell(text: "+ Add Restaurant", type: .rButton))
            inputCells.append(dayArray)
        }
        return inputCells
    }
}

extension NewTripViewController : UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return CELL_HEIGHT
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if section == 0 {
            return UIView(frame: CGRect(x: 0, y: 0, width: tableView.frame.width, height: CELL_HEIGHT))
        }
        else {
            return HeaderLabelView(frame: CGRect(x: 0, y: 0, width: tableView.frame.width, height: HEADER_LABEL_HEIGHT), dayNum: section - 1)
        }
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if section == 0 {
            return CELL_HEIGHT
        }
        else {
            return HEADER_LABEL_HEIGHT
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let cell = cells[indexPath.section-1][indexPath.row]
        if cell.type == .aButton {
            if !trip.days[indexPath.section-1].attractions.contains("") {
                trip.days[indexPath.section-1].attractions.append("")
            }
        }
        else if cell.type == .rButton {
            if !trip.days[indexPath.section-1].restaurants.contains("") {
                trip.days[indexPath.section-1].restaurants.append("")
            }
        }
        cells = createCellsFromTrip(trip: self.trip)
        tableView.reloadData()
    }
    
}


extension NewTripViewController : UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1 + trip.days.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return 2
        }
        else {
            return 2 + trip.days[section - 1].attractions.count + trip.days[section - 1].restaurants.count
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        //for the first section
        if indexPath.section == 0 {
            if indexPath.row == 0 {
                //for the trip name cell
                let cell = tableView.dequeueReusableCell(withIdentifier: inputReuseIdentifier, for: indexPath) as! InputTableViewCell
                cell.cellType = .input
                cell.inputField.text = trip.name == "" ? "New trip": trip.name
                cell.selectionStyle = .none
                cell.didModifyInputField = { newText in
                    self.cells[indexPath.section][indexPath.row].text = newText
                    self.trip.name = newText
                }
                return cell
            }
            else {
                //for the location cell
                let cell = tableView.dequeueReusableCell(withIdentifier: inputReuseIdentifier, for: indexPath) as! InputTableViewCell
                cell.selectionStyle = .none
                cell.cellType = .input
                cell.inputField.attributedPlaceholder =
                    self.trip.location == "" ? NSAttributedString(string: "Location", attributes: placeholderAttrs) : NSAttributedString(string: trip.location, attributes: labelAttrs)
                cell.selectionStyle = .none
                cell.didModifyInputField = { newText in
                    self.cells[indexPath.section][indexPath.row].text = newText
                    self.trip.location = newText
                }
                return cell
            }
        }
            //for all other sections
        else {
            let pathCell = cells[indexPath.section-1][indexPath.row]
            //input cells
            if pathCell.type == .ainput {
                let cell = tableView.dequeueReusableCell(withIdentifier: inputReuseIdentifier, for: indexPath) as! InputTableViewCell
                cell.cellType = .ainput
                cell.selectionStyle = .none
                cell.inputField.text = pathCell.text
                cell.inputField.attributedPlaceholder = NSAttributedString(string: randomAttraction(index: indexPath.row+indexPath.section), attributes: placeholderAttrs)
                cell.didModifyInputField = { newText in
                    self.trip.days[indexPath.section - 1].attractions[indexPath.row] = newText
                }
                return cell
            }
            if pathCell.type == .rinput {
                let cell = tableView.dequeueReusableCell(withIdentifier: inputReuseIdentifier, for: indexPath) as! InputTableViewCell
                cell.cellType = .rinput
                cell.selectionStyle = .none
                cell.inputField.text = pathCell.text
                cell.inputField.attributedPlaceholder = NSAttributedString(string: randomRestaurant(index: indexPath.row+indexPath.section), attributes: placeholderAttrs)
                cell.didModifyInputField = { newText in
                 self.trip.days[indexPath.section - 1].restaurants[indexPath.row-(self.trip.days[indexPath.section-1].attractions.count+1)] = newText
                }
                return cell
            }
            //add attraction cells
            else if cells[indexPath.section-1][indexPath.row].type == .aButton {
                let cell = tableView.dequeueReusableCell(withIdentifier: buttonReuseIdentifier, for: indexPath) as! ButtonTableViewCell
                cell.cellType = .aButton
                cell.buttonLabel.text = pathCell.text
                cell.buttonLabel.textColor = .SKY
                return cell
            }
                //add restaurant cells
            else {
                let cell = tableView.dequeueReusableCell(withIdentifier: buttonReuseIdentifier, for: indexPath) as! ButtonTableViewCell
                cell.cellType = .rButton
                cell.buttonLabel.text = pathCell.text
                cell.buttonLabel.textColor = .SKY
                return cell
            }
        }
    }
}

extension NewTripViewController : AddDayDelegate {
    func addDay() {
        self.trip.days.append(Day(num: trip.days.count+1, attractions: [""], restaurants: [""]))
        reloadDelegate.reloadTrips(trip: nil)
        self.cells = createCellsFromTrip(trip: self.trip)
        self.tableView.reloadData()
    }
}
