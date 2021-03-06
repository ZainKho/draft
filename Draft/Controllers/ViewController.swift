//
//  ViewController.swift
//  Draft
//
//  Created by Olivia on 11/16/19.
//

import UIKit
import SnapKit

protocol PresentEditCardDelegate: class {
    func presentEditViewController(trip: Trip, title: String)
}

protocol PresentNewTripDelegate: class {
    func presentNewTripViewController(trip: Trip, title: String)
}

protocol ReloadTripDelegate: class {
    func reloadTrips(trip: Trip?)
}

protocol AddDayDelegate: class {
    func addDay()
}

protocol EmptyStateDelegate: class {
    func dismissEmptyState()
}

class ViewController: UIViewController {
    
    var collectionView: UICollectionView!
    var headerGradientView: UIView!
    var headerGradient: CAGradientLayer!
    var footerGradientView: UIView!
    var footerGradient: CAGradientLayer!
    var emptyState: EmptyStateView!
    
    let tripCellReuseIdentifier = "tripCellReuseIdentifier"
    let headerViewReuseIdentifier = "filterViewReuseIdentifier"
    
    var trips = [Trip]()
    
    let HEADER_HEIGHT: CGFloat = 168
    let CELL_HEIGHT: CGFloat = 168
    let GRADIENT_HEIGHT: CGFloat = 96
    let SPACING_168: CGFloat = 168
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.navigationBar.setBackgroundImage(UIImage(), for: UIBarMetrics.default)
        navigationController?.navigationBar.shadowImage = UIImage()
        navigationController?.navigationBar.isTranslucent = true
        
        view.backgroundColor = .BREEZE
        
        // headerGradient
        headerGradientView = UIView()
        headerGradient = CAGradientLayer()
        headerGradient.colors = [UIColor.BREEZE.cgColor, UIColor.CLEAR.cgColor]
        headerGradientView.layer.insertSublayer(headerGradient, at: 0)
        view.addSubview(headerGradientView)
        
        // footerGradient
        footerGradientView = UIView()
        footerGradient = CAGradientLayer()
        footerGradient.colors = [UIColor.CLEAR.cgColor, UIColor.BREEZE.cgColor]
        footerGradientView.layer.insertSublayer(footerGradient, at: 0)
        view.addSubview(footerGradientView)

        // Set up tripsLayout
        let tripsLayout = UICollectionViewFlowLayout()
        tripsLayout.scrollDirection = .vertical
        tripsLayout.minimumLineSpacing = SPACING_24
        tripsLayout.minimumInteritemSpacing = SPACING_24
        tripsLayout.sectionInset.left = SPACING_16
        tripsLayout.sectionInset.right = SPACING_16
        
        // Set up collectionView
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: tripsLayout)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.backgroundColor = .none
        
        // Register cell
        collectionView.register(TripCollectionViewCell.self, forCellWithReuseIdentifier: tripCellReuseIdentifier)
        collectionView.register(HeaderView.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: headerViewReuseIdentifier)
        collectionView.dataSource = self
        collectionView.delegate = self
        view.addSubview(collectionView)
        
        // Bring cloudy gradients to front
        view.bringSubviewToFront(headerGradientView)
        view.bringSubviewToFront(footerGradientView)
        
        // emptyState
        emptyState = EmptyStateView()
        emptyState.presentDelegate = self
        view.addSubview(emptyState)
        emptyState.alpha = trips.isEmpty ? 1 : 0
        
        if let userID = UserDefaults.standard.value(forKey: "user") as? Int {
            Networking.shared.getUserTrips(forUser: userID) { (trips) in
                self.trips = convertBackendTrips(trips: trips)
                DispatchQueue.main.async {
                    self.emptyState.alpha = trips.isEmpty ? 1 : 0
                    self.collectionView.reloadData()
                }
            }
        }
        
        setupConstraints()
        
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        headerGradient.frame = headerGradientView.bounds
        footerGradient.frame = footerGradientView.bounds
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if collectionView.contentOffset.y <= 1 {
            headerGradient.opacity = 0
        }
        else {
            headerGradient.opacity = 1
        }
    }

    func setupConstraints() {
        
        headerGradientView.snp.makeConstraints { (make) in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.topMargin)
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(GRADIENT_HEIGHT)
        }
        
        footerGradientView.snp.makeConstraints { (make) in
            make.bottom.leading.trailing.equalToSuperview()
            make.height.equalTo(GRADIENT_HEIGHT)
        }
        
        collectionView.snp.makeConstraints { (make) in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.topMargin)
            make.bottom.leading.trailing.equalToSuperview()
        }
        
        emptyState.snp.makeConstraints { (make) in
            make.top.equalToSuperview().offset(SPACING_168)
            make.leading.bottom.trailing.equalToSuperview()
        }
    }
    
    @objc func backButtonPushed() {
        navigationController?.popViewController(animated: true)
    }
}
    
extension ViewController: UICollectionViewDataSource {
    
    // collectionView
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return trips.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: tripCellReuseIdentifier, for: indexPath) as! TripCollectionViewCell
        cell.configure(for: trips[indexPath.row])
        cell.presentDelegate = self
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        let headerView = collectionView.dequeueReusableSupplementaryView(ofKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: headerViewReuseIdentifier, for: indexPath) as! HeaderView
        headerView.presentDelegate = self
        
        return headerView
    }
}

extension ViewController: UICollectionViewDelegateFlowLayout {
    
    // collectionView
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let w = collectionView.frame.width - SPACING_16*2
        
        return CGSize(width: w, height: CELL_HEIGHT)
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let trip = trips[indexPath.row]
        let viewController = TripViewController(trip: trip)
        
        // Back button
        let backButton = UIBarButtonItem(title: "Back", style: .done, target: self, action: #selector(backButtonPushed))
        backButton.tintColor = .BREEZE
        navigationItem.backBarButtonItem = backButton
        
        navigationController?.pushViewController(viewController, animated: true)
        
    }
    
    // HeaderView
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        
        let w = collectionView.frame.width - SPACING_16*2
        return CGSize(width: w, height: HEADER_HEIGHT)
    }
}

extension ViewController : PresentEditCardDelegate {
    func presentEditViewController(trip: Trip, title: String) {
        let viewController = EditTripViewController(trip: trip, title: title)
        viewController.reloadDelegate = self
        let editTripViewController = UINavigationController(rootViewController: viewController)
        
        present(editTripViewController, animated: true, completion: nil)
    }
    
}

extension ViewController: ReloadTripDelegate {
    func reloadTrips(trip: Trip?) {
        if let newTrip = trip {
            trips.insert(newTrip, at: 0)
        }
        self.collectionView.reloadData()
    }
}

extension ViewController: PresentNewTripDelegate {
    func presentNewTripViewController(trip: Trip, title: String) {
        let viewController = NewTripViewController(trip: trip, title: title)
        viewController.reloadDelegate = self
        viewController.emptyStateDelegate = self
        let newTripViewController = UINavigationController(rootViewController: viewController)
        
        present(newTripViewController, animated: true, completion: nil)
    }
}

extension ViewController: EmptyStateDelegate {
    func dismissEmptyState() {
        emptyState.alpha = 0
    }
}
