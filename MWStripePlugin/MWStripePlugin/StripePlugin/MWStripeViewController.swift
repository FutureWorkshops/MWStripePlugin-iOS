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
    private var purchaseableItems: [PurchaseableItem] = [.init(imageURL: "https://images.unsplash.com/photo-1557682224-5b8590cd9ec5?ixlib=rb-1.2.1&q=80&fm=jpg&crop=entropy&cs=tinysrgb&w=2000&fit=max&ixid=eyJhcHBfaWQiOjExNzczfQ", text: "This is a sample title", detailText: "This is a sample subtitle", amount: "£25")]
    private var paymentSheet: PaymentSheet?
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.tableFooterView = UIView()
        tableView.dataSource = self
        tableView.delegate = self
        tableView.separatorStyle = .none
        
        let VStack = UIStackView(arrangedSubviews: [tableView, navigationFooterView])
        VStack.axis = .vertical
        self.view.addPinnedSubview(VStack)
        
        self.loadItemsToPurchase()
        
        self.configureButton(title: "Loading...", isEnabled: false)
        self.fetchStripeConfiguration()
    }
    
    private func configureButton(title: String, isEnabled: Bool) {
        self.navigationFooterConfig = NavigationFooterView.Config(primaryButton: ButtonConfig(isEnabled: isEnabled, style: .primary, title: title, action: didTapCheckoutButton),
                                                                  secondaryButton: nil,
                                                                  hasBlurredBackground: false)
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
}

extension MWStripeViewController: UITableViewDataSource, UITableViewDelegate {
    
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.purchaseableItems.count
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let item = self.purchaseableItems[indexPath.row]
        let cell = tableView.cellForRow(at: indexPath) ?? UITableViewCell(style: .subtitle, reuseIdentifier: "reuseIdentifier")
        
        if let imageURL = item.imageURL {
            let cancellable = self.stripeStep.services.imageLoadingService.asyncLoad(image: imageURL, session: self.stripeStep.session) { [weak self] image in
                cell.imageView?.image = image?.resized(to: CGSize(width: 57, height: 57), preservingAspectRatio: true)
                cell.imageView?.frame = CGRect(x: 0, y: 0, width: 57, height: 57)
                cell.imageView?.contentMode = .scaleAspectFit
                cell.imageView?.layer.cornerRadius = 4
                cell.imageView?.layer.masksToBounds = true
                cell.setNeedsLayout()
                self?.ongoingImageLoads.removeValue(forKey: indexPath)
            }
            self.ongoingImageLoads[indexPath] = cancellable
        }
        
        cell.textLabel?.text = item.text
        cell.textLabel?.numberOfLines = 0
        cell.textLabel?.font = UIFont.preferredFont(forTextStyle: .headline)
        
        cell.detailTextLabel?.text = item.detailText
        cell.detailTextLabel?.numberOfLines = 0
        cell.detailTextLabel?.textColor = .secondaryLabel
        
        let amountLabel = UILabel()
        amountLabel.text = item.amount
        amountLabel.font = UIFont.preferredFont(forTextStyle: .title3, weight: .bold)
        amountLabel.sizeToFit()
        cell.accessoryView = amountLabel
        
        return cell
    }
    
    public func tableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if let imageLoad = self.ongoingImageLoads[indexPath] {
            imageLoad.cancel()
            self.ongoingImageLoads.removeValue(forKey: indexPath)
        }
    }
}

//MARK: Stripe
extension MWStripeViewController {
    
    // Load the configuration when tapping the payment button
    private func fetchStripeConfiguration() {
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
                    self.paymentSheet = PaymentSheet(paymentIntentClientSecret: response.paymentIntent, configuration: configuration)

                    self.configureButton(title: "Pay with Stripe", isEnabled: true)
                case .failure(let error):
                    self.show(error)
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
                    let purchaseResult = MWStripePurchaseResult(identifier: self.stripeStep.identifier, success: response.paymentSuccessful)
                    self.addStepResult(purchaseResult)
                    self.goForward()
                case .failure(let error):
                    self.show(error)
                }
            }
        }
    }
}
