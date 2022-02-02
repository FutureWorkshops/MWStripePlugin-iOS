//
//  MWStripeViewController.swift
//  MWStripePlugin
//
//  Created by Xavi Moll on 14/1/21.
//

import Stripe
import Combine
import Foundation
import MobileWorkflowCore

struct PurchaseableItem: Decodable {
    let imageURL: String?
    let text: String
    let detailText: String?
    let amount: String
}

struct StripeConfigurationResponse: Decodable {
    let paymentIntent: String
    let ephemeralKey: String
    let customer: String
    let publishableKey: String
    let merchantName: String?
}

struct StripeConfirmationResponse: Decodable {
    let paymentSuccessful: Bool
    let paymentStatusMessage: String?
}

public class MWStripeViewController: MWStepViewController {
    
    //MARK: private properties
    private let tableView = UITableView(frame: .zero, style: .insetGrouped)
    private var ongoingImageLoads: [IndexPath: AnyCancellable] = [:]
    
    private var stripeStep: MWStripeStep { self.mwStep as! MWStripeStep }
    private var purchaseableItems: [PurchaseableItem] = [.init(imageURL: nil, text: L10n.loading, detailText: nil, amount: "")]
    private var paymentSheet: PaymentSheet?
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.tableFooterView = UIView()
        tableView.dataSource = self
        tableView.delegate = self
        tableView.separatorStyle = .none
        tableView.contentInset = .init(top: 16, left: 0, bottom: 0, right: 0)
        tableView.register(MWStripePurchaseCell.self, forCellReuseIdentifier: "reuseIdentifier")
        
        let VStack = UIStackView(arrangedSubviews: [tableView, navigationFooterView])
        VStack.axis = .vertical
        self.view.addPinnedSubview(VStack)
        
        self.loadItemsToPurchase()
    }
    
    private func configureButton(title: String, isEnabled: Bool, action: @escaping (() -> Void)) {
        self.navigationFooterConfig = NavigationFooterView.Config(primaryButton: ButtonConfig(isEnabled: isEnabled, style: .primary, title: title, action: action),
                                                                  secondaryButton: nil,
                                                                  hasBlurredBackground: false)
    }
    
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Fetch every time that the view appears in case that the suer navigates back. If they do,
        // the server will error out and we'll display a "continue" button if they've already paid.
        self.fetchStripeConfiguration()
    }
    
    //MARK: Actions
    private func didTapCheckoutButton() {
        paymentSheet?.present(from: self) { paymentResult in
            let status: String
            switch paymentResult {
            case .completed:
                status = "succeeded"
            case .canceled:
                status = "cancelled"
            case .failed(let error):
                status = "failed"
            }
            self.validateStripeStatus(status: status)
        }
    }
    
    // MARK: Content
    private func loadItemsToPurchase() {
        guard let url = self.stripeStep.session.resolve(url: stripeStep.contentURL) else {
            assertionFailure("Failed to resolve the URL")
            return
        }
        
        let task = URLAsyncTask<[PurchaseableItem]>.build(
            url: url,
            method: .GET,
            session: stripeStep.session,
            parser: { try JSONDecoder().decode([PurchaseableItem].self, from: $0) }
        )
        
        self.stripeStep.services.perform(task: task, session: stripeStep.session) { [weak self] result in
            guard let self = self else { return }
            DispatchQueue.main.async {
                switch result {
                case .success(let response):
                    self.purchaseableItems = response
                    self.tableView.reloadData()
                case .failure(let error):
                    self.show(error)
                }
            }
        }
    }
    
    //MARK: Stripe
    private func fetchStripeConfiguration() {
        self.configureButton(title: L10n.loading, isEnabled: false, action: {})
        guard let url = self.stripeStep.session.resolve(url: stripeStep.paymentIntentURL) else {
            assertionFailure("Failed to resolve the URL")
            return
        }
        
        let task = URLAsyncTask<StripeConfigurationResponse>.build(
            url: url,
            method: .POST,
            session: stripeStep.session,
            parser: { try StripeConfigurationResponse.parse(data: $0) }
        )
        
        self.stripeStep.services.perform(task: task, session: stripeStep.session) { [weak self] result in
            guard let self = self else { return }
            DispatchQueue.main.async {
                switch result {
                case .success(let response):
                    STPAPIClient.shared.publishableKey = response.publishableKey
                    
                    var configuration = PaymentSheet.Configuration()
                    configuration.customer = .init(id: response.customer, ephemeralKeySecret: response.ephemeralKey)
                    if let merchantName = response.merchantName {
                        configuration.merchantDisplayName = merchantName
                    }
                    self.paymentSheet = PaymentSheet(paymentIntentClientSecret: response.paymentIntent, configuration: configuration)

                    self.configureButton(title: L10n.payWithStripe, isEnabled: true, action: self.didTapCheckoutButton)
                case .failure(let error):
                    // A 409 means that the user has already paid: https://futureworkshops.atlassian.net/browse/WELBA-88
                    if (error as NSError).code == 409 {
                        self.configureButton(title: L10n.continue, isEnabled: true) {
                            self.goForward()
                        }
                    } else {
                        self.show(error)
                    }
                }
            }
        }
    }
    
    // Validate against the server what the SDK has returned
    private func validateStripeStatus(status: String) {
        guard let url = self.stripeStep.session.resolve(url: stripeStep.paymentIntentURL) else {
            assertionFailure("Failed to resolve the URL")
            return
        }
        
        let task = URLAsyncTask<StripeConfirmationResponse>.build(
            url: url,
            method: .PUT,
            body: try? JSONSerialization.data(withJSONObject: ["status":status], options: []),
            session: stripeStep.session,
            headers: ["Content-Type":"application/json"],
            parser: { try StripeConfirmationResponse.parse(data: $0) }
        )
        
        self.stripeStep.services.perform(task: task, session: stripeStep.session) { [weak self] result in
            guard let self = self else { return }
            DispatchQueue.main.async {
                switch result {
                case .success(let response):
                    let purchaseResult = MWStripePurchaseResult(identifier: self.stripeStep.identifier,
                                                                paymentSuccessful: response.paymentSuccessful,
                                                                paymentStatusMessage: response.paymentStatusMessage)
                    self.addStepResult(purchaseResult)
                    self.goForward()
                case .failure(let error):
                    self.show(error)
                }
            }
        }
    }
}

extension MWStripeViewController: UITableViewDataSource, UITableViewDelegate {
    
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.purchaseableItems.count
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let item = self.purchaseableItems[indexPath.row]
        let cell: MWStripePurchaseCell = tableView.cellForRow(at: indexPath) as? MWStripePurchaseCell ?? MWStripePurchaseCell(style: .default, reuseIdentifier: "reuseIdentifier")
        cell.configure(with: item)
        
        if let imageURL = item.imageURL {
            let cancellable = self.stripeStep.services.imageLoadingService.asyncLoad(image: imageURL, session: self.stripeStep.session) { [weak self] image in
                (cell.stackView.arrangedSubviews.first(where: { $0 is UIImageView }) as? UIImageView)?.image = image
                cell.setNeedsLayout()
                self?.ongoingImageLoads.removeValue(forKey: indexPath)
            }
            self.ongoingImageLoads[indexPath] = cancellable
        }
        
        return cell
    }
    
    public func tableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if let imageLoad = self.ongoingImageLoads[indexPath] {
            imageLoad.cancel()
            self.ongoingImageLoads.removeValue(forKey: indexPath)
        }
    }
}
