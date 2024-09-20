//
//  ChatBotViewController.swift
//  datafight
//
//  Created by younes ouasmi on 13/09/2024.
//

import UIKit

protocol ChatBotViewControllerDelegate: AnyObject {
    func didSaveGraphConfiguration(_ config: GraphConfiguration)
}

class ChatBotViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, OptionsViewDelegate {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var optionsContainerView: UIView!
    
    weak var delegate: ChatBotViewControllerDelegate?

    var messages: [ChatMessage] = []
    let optionsView = OptionsView()
    let chatBotManager = ChatBotManager()
    let chartOptionsStackView = UIStackView()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupTableView()
        setupOptionsView()
        setupChartOptionsView()
        startConversation()
        optionsView.delegate = self

        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 60
        
        showChartOptions()

    }
    func showChartOptions() {
        chartOptionsStackView.isHidden = false
        optionsView.isHidden = true
    }
    // MARK: - Setup Methods

    func setupTableView() {
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(BotMessageCell.self, forCellReuseIdentifier: "BotMessageCell")
        tableView.register(UserMessageCell.self, forCellReuseIdentifier: "UserMessageCell")
    }

    func setupOptionsView() {
        optionsView.delegate = self
        optionsView.translatesAutoresizingMaskIntoConstraints = false
        optionsContainerView.addSubview(optionsView)

        NSLayoutConstraint.activate([
            optionsView.leadingAnchor.constraint(equalTo: optionsContainerView.leadingAnchor),
            optionsView.trailingAnchor.constraint(equalTo: optionsContainerView.trailingAnchor),
            optionsView.topAnchor.constraint(equalTo: optionsContainerView.topAnchor),
            optionsView.bottomAnchor.constraint(equalTo: optionsContainerView.bottomAnchor)
        ])
    }

    private func setupChartOptionsView() {
        view.addSubview(chartOptionsStackView)
        chartOptionsStackView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            chartOptionsStackView.topAnchor.constraint(equalTo: tableView.bottomAnchor, constant: 20),
            chartOptionsStackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            chartOptionsStackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            chartOptionsStackView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20)
        ])

        chartOptionsStackView.axis = .horizontal
        chartOptionsStackView.distribution = .fillEqually
        chartOptionsStackView.spacing = 10

        for type in VisualizationType.allCases {
            let optionView = ChartTypeOptionView(type: type)
            optionView.isUserInteractionEnabled = true
            let tapGesture = UITapGestureRecognizer(target: self, action: #selector(chartTypeSelected(_:)))
            optionView.addGestureRecognizer(tapGesture)
            chartOptionsStackView.addArrangedSubview(optionView)
        }

        chartOptionsStackView.isHidden = true
    }

    // MARK: - Chat Methods

    func startConversation() {
        let firstMessage = ChatMessage(sender: .bot, content: chatBotManager.getBotMessage())
        insertNewMessage(firstMessage)
        updateOptions()
    }

    func insertNewMessage(_ message: ChatMessage) {
        print("Nouveau message inséré : \(message.content) de \(message.sender)")
        messages.append(message)
        let indexPath = IndexPath(row: messages.count - 1, section: 0)
        tableView.insertRows(at: [indexPath], with: .fade)
        tableView.scrollToRow(at: indexPath, at: .bottom, animated: true)
    }

    func updateOptions() {
        chatBotManager.getOptions { [weak self] options in
            DispatchQueue.main.async {
                if self?.chatBotManager.currentStep == .selectVisualizationType {
                    self?.showChartOptions()
                } else {
                    self?.optionsView.options = options
                    self?.optionsView.isHidden = false
                    self?.chartOptionsStackView.isHidden = true
                }
            }
        }
    }

    private func updateChatWithUserOption(_ option: String) {
        print("updateChatWithUserOption appelé avec l'option : \(option)")
        
        let userMessage = ChatMessage(sender: .user, content: option)
        insertNewMessage(userMessage)
        proceedToNextStep()
    }

    private func updateChatWithUserOptions(_ options: [String]) {
        print("updateChatWithUserOptions appelé avec les options : \(options)")
        
        let optionsText = options.joined(separator: ", ")
        let userMessage = ChatMessage(sender: .user, content: optionsText)
        insertNewMessage(userMessage)

        proceedToNextStep()
    }

    private func proceedToNextStep() {
        print("proceedToNextStep appelé")
        
        let botMessageContent = chatBotManager.getBotMessage()
        print("Message du bot : \(botMessageContent)")
        
        let botMessage = ChatMessage(sender: .bot, content: botMessageContent)
        insertNewMessage(botMessage)

        chatBotManager.getOptions { [weak self] options in
            DispatchQueue.main.async {
                print("Nouvelles options reçues : \(options)")
                self?.optionsView.options = options
                let allowsMultipleSelection = self?.chatBotManager.allowsMultipleSelection() ?? false
                print("allowsMultipleSelection mis à jour : \(allowsMultipleSelection)")
                self?.optionsView.allowsMultipleSelection = allowsMultipleSelection
            }
        }
    }

    // MARK: - OptionsViewDelegate

    func optionSelected(_ option: String) {
        print("Option sélectionnée : \(option)")
        chatBotManager.processUserSelection(option)
        updateChatWithUserOption(option)
    }

    func optionsValidated(_ selectedOptions: [String]) {
        print("optionsValidated appelé avec les options : \(selectedOptions)")
        
        chatBotManager.processMultipleSelections(selectedOptions)
        updateChatWithUserOptions(selectedOptions)
    }

    // MARK: - Chart Type Selection

    @objc private func chartTypeSelected(_ gesture: UITapGestureRecognizer) {
        guard let selectedView = gesture.view as? ChartTypeOptionView,
              let selectedType = VisualizationType.allCases.first(where: { $0.rawValue == selectedView.label.text }) else {
            return
        }
        chatBotManager.processUserSelection(selectedType.rawValue)
        updateChatWithUserOption(selectedType.rawValue)
        chartOptionsStackView.isHidden = true
        optionsView.isHidden = false
    }

    // MARK: - Configuration Finishing

    func finishConfiguration() {
        if let config = chatBotManager.graphConfigurationBuilder.buildGraphConfiguration() {
            FirebaseService.shared.saveGraphConfiguration(config) { [weak self] result in
                switch result {
                case .success:
                    self?.delegate?.didSaveGraphConfiguration(config)
                    self?.dismiss(animated: true, completion: nil)
                case .failure(let error):
                    let alert = UIAlertController(title: "Erreur", message: "Impossible de sauvegarder la configuration : \(error.localizedDescription)", preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                    self?.present(alert, animated: true, completion: nil)
                }
            }
        } else {
            let alert = UIAlertController(title: "Erreur", message: "Impossible de créer la configuration du graphique.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            present(alert, animated: true, completion: nil)
        }
    }

    // MARK: - UITableViewDataSource

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return messages.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let message = messages[indexPath.row]

        if message.sender == .bot {
            guard let cell = tableView.dequeueReusableCell(withIdentifier: "BotMessageCell", for: indexPath) as? BotMessageCell else {
                return UITableViewCell()
            }
            cell.messageLabel.text = message.content
            return cell
        } else {
            guard let cell = tableView.dequeueReusableCell(withIdentifier: "UserMessageCell", for: indexPath) as? UserMessageCell else {
                return UITableViewCell()
            }
            cell.messageLabel.text = message.content
            return cell
        }
    }
}

// MARK: - ChartTypeOptionView

class ChartTypeOptionView: UIView {
    let imageView = UIImageView()
    let label = UILabel()

    init(type: VisualizationType) {
        super.init(frame: .zero)
        setupViews()
        configure(with: type)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupViews() {
        addSubview(imageView)
        addSubview(label)

        imageView.translatesAutoresizingMaskIntoConstraints = false
        label.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: topAnchor),
            imageView.leadingAnchor.constraint(equalTo: leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: trailingAnchor),
            imageView.heightAnchor.constraint(equalTo: imageView.widthAnchor),

            label.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 8),
            label.leadingAnchor.constraint(equalTo: leadingAnchor),
            label.trailingAnchor.constraint(equalTo: trailingAnchor),
            label.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])

        label.textAlignment = .center
        label.numberOfLines = 0
    }

    func configure(with type: VisualizationType) {
        imageView.image = UIImage(named: type.imageName)
        label.text = type.rawValue
    }
}
