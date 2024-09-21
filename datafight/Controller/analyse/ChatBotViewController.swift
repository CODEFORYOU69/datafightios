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

class ChatBotViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, OptionsViewDelegate, UITextFieldDelegate {

        @IBOutlet weak var tableView: UITableView!
        @IBOutlet weak var optionsContainerView: UIView!
    @IBOutlet weak var textInputView: UITextField!
        @IBOutlet weak var sendButton: UIButton!
        
    @IBOutlet weak var stackView: UIStackView!
    weak var delegate: ChatBotViewControllerDelegate?

        var messages: [ChatMessage] = []
        let optionsView = OptionsView()
        let chatBotManager = ChatBotManager()
        let chartOptionsStackView = UIStackView()
        private var configNameTextField: UITextField?



        override func viewDidLoad() {
            super.viewDidLoad()
            setupTableView()
            setupOptionsView()
            setupChartOptionsView()
            startConversation()
            optionsView.delegate = self
            textInputView.isHidden = true
            sendButton.isHidden = true

            tableView.rowHeight = UITableView.automaticDimension
            tableView.estimatedRowHeight = 60
            
            showChartOptions()

            NotificationCenter.default.addObserver(self, selector: #selector(handleConfigurationFinished(_:)), name: .configurationFinished, object: nil)
    NotificationCenter.default.addObserver(self, selector: #selector(handleConfigurationEnded), name: .configurationEnded, object: nil)


        }
    @IBAction func sendButtonTapped(_ sender: UIButton) {
        guard let userInput = textInputView.text, !userInput.isEmpty else {
            // Gérer le cas où l'entrée est vide si nécessaire
            return
        }
        processUserInput(userInput)
    }

    private func processUserInput(_ input: String) {
        // Insérer le message de l'utilisateur dans le chat
        insertNewMessage(ChatMessage(sender: .user, content: input))

        // Traiter la sélection de l'utilisateur
        chatBotManager.processUserSelection(input)

        // Passer à l'étape suivante
        proceedToNextStep()

        // Effacer le champ de texte
        textInputView.text = ""
    }

    func showTextInput(for option: String) {
        let alertController = UIAlertController(title: "Saisie", message: option, preferredStyle: .alert)
        
        alertController.addTextField { textField in
            textField.placeholder = "Entrez votre réponse ici"
        }
        
        let confirmAction = UIAlertAction(title: "Confirmer", style: .default) { [weak self] _ in
            if let textField = alertController.textFields?.first,
               let userInput = textField.text, !userInput.isEmpty {
                self?.processTextInput(userInput)
            } else {
                // Gérer le cas où l'utilisateur n'a rien entré
                self?.showAlert(title: "Erreur", message: "Veuillez entrer une valeur.")
            }
        }
        
        let cancelAction = UIAlertAction(title: "Annuler", style: .cancel)
        
        alertController.addAction(confirmAction)
        alertController.addAction(cancelAction)
        
        present(alertController, animated: true)
    }

    func processTextInput(_ text: String) {
        chatBotManager.processUserSelection(text)
        updateUI()
    }

    func showAlert(title: String, message: String) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK", style: .default)
        alertController.addAction(okAction)
        present(alertController, animated: true)
    }

   
        @objc func handleConfigurationFinished(_ notification: Notification) {
    if let config = notification.object as? GraphConfiguration {
        showGeneratedGraph(with: config)
    }
}
@objc func handleConfigurationEnded() {
    DispatchQueue.main.async {
        self.dismiss(animated: true, completion: nil)
    }
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
        func updateOptionsView(with options: [String]) {
            if chatBotManager.currentStep == .enterConfigurationName {
                showConfigNameInput()
            } else {
                hideConfigNameInput()
                optionsView.options = options
            }
        }
        
        private func showConfigNameInput() {
            optionsView.isHidden = true
            
            if configNameTextField == nil {
                configNameTextField = UITextField()
                configNameTextField?.placeholder = "Entrez un nom pour votre configuration"
                configNameTextField?.borderStyle = .roundedRect
                configNameTextField?.returnKeyType = .done
                configNameTextField?.delegate = self
                
                view.addSubview(configNameTextField!)
                configNameTextField?.translatesAutoresizingMaskIntoConstraints = false
                NSLayoutConstraint.activate([
                    configNameTextField!.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
                    configNameTextField!.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
                    configNameTextField!.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
                    configNameTextField!.heightAnchor.constraint(equalToConstant: 44)
                ])
            }
            
            configNameTextField?.isHidden = false
            configNameTextField?.becomeFirstResponder()
        }

        private func hideConfigNameInput() {
            configNameTextField?.isHidden = true
            configNameTextField?.resignFirstResponder()
            optionsView.isHidden = false
        }

    func updateUI() {
        let botMessage = chatBotManager.getBotMessage()
        insertNewMessage(ChatMessage(sender: .bot, content: botMessage))
        
        chatBotManager.getOptions { [weak self] options in
            DispatchQueue.main.async {
                if options.isEmpty {
                    // Pas d'options, afficher le TextField
                    self?.optionsView.isHidden = true
                    self?.textInputView.isHidden = false
                    self?.sendButton.isHidden = false
                    self?.stackView.removeFromSuperview()

                } else {
                    // Des options sont disponibles, afficher optionsView
                    self?.optionsView.allowsMultipleSelection = true // ou false selon le cas
                    self?.optionsView.isHidden = false
                    self?.textInputView.isHidden = true
                    self?.sendButton.isHidden = true
                    self?.optionsView.options = options


                }
                
                // Gérer les autres éléments de l'interface si nécessaire
                if case .configureData = self?.chatBotManager.currentStep {
                    self?.optionsView.isHidden = false
                    self?.chartOptionsStackView.isHidden = true
                } else if self?.chatBotManager.currentStep == .selectVisualizationType {
                    self?.showChartOptions()
                } else {
                    self?.hideChartOptions()
                }
                
                if self?.chatBotManager.currentStep == .end {
                    self?.showGeneratedGraph(with: self?.chatBotManager.graphConfigurationBuilder.buildGraphConfiguration() ?? GraphConfiguration(name: "", visualizationType: .barChart, dataConfigurations: [], chartOptions: ChartOptions()))
                }
            }
        }
    }

func showGeneratedGraph(with configuration: GraphConfiguration) {
            let graphGenerator = GraphGenerator()
    var graphView: UIView?

    let dataConfigurations = configuration.dataConfigurations.flatMap { configuredData -> [DataConfiguration] in
        return configuredData.parameters.map { parameter in
            let attribute = parameter.selections.first?.attribute ?? Attribute.fighter(.firstName)
            let filter = parameter.filters.first
            return DataConfiguration(entityType: parameter.mainEntity, attribute: attribute, filter: filter)
        }
    }

    switch configuration.visualizationType {
    case .barChart:
        graphView = graphGenerator.generateBarChart(data: dataConfigurations, options: configuration.chartOptions)
    case .lineChart:
        graphView = graphGenerator.generateLineChart(data: dataConfigurations, options: configuration.chartOptions)
    case .pieChart:
        graphView = graphGenerator.generatePieChart(data: dataConfigurations, options: configuration.chartOptions)
    case .scatterPlot:
        graphView = graphGenerator.generateScatterPlot(data: dataConfigurations, options: configuration.chartOptions)
    case .radarChart:
        graphView = graphGenerator.generateRadarChart(data: dataConfigurations, options: configuration.chartOptions)
    }

    guard let graphView = graphView else {
        print("Erreur : Impossible de générer le graphique")
        return
    }

            // Configurer la vue du graphique
            DispatchQueue.main.async { [weak self] in
        let graphViewController = UIViewController()
        graphViewController.view.backgroundColor = .white
        graphViewController.view.addSubview(graphView)
        
        graphView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            graphView.topAnchor.constraint(equalTo: graphViewController.view.safeAreaLayoutGuide.topAnchor, constant: 20),
            graphView.leadingAnchor.constraint(equalTo: graphViewController.view.leadingAnchor, constant: 20),
            graphView.trailingAnchor.constraint(equalTo: graphViewController.view.trailingAnchor, constant: -20),
            graphView.heightAnchor.constraint(equalTo: graphView.widthAnchor)
        ])

        let titleLabel = UILabel()
        titleLabel.text = configuration.name
        titleLabel.textAlignment = .center
        titleLabel.font = UIFont.boldSystemFont(ofSize: 18)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        graphViewController.view.addSubview(titleLabel)

        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: graphView.bottomAnchor, constant: 20),
            titleLabel.leadingAnchor.constraint(equalTo: graphViewController.view.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: graphViewController.view.trailingAnchor, constant: -20)
        ])

        self?.present(graphViewController, animated: true, completion: nil)
    }

            // Sauvegarder la configuration dans Firebase
           FirebaseService.shared.saveGraphConfiguration(configuration) { result in
        switch result {
        case .success:
            print("Configuration du graphique sauvegardée avec succès")
        case .failure(let error):
            print("Erreur lors de la sauvegarde de la configuration du graphique : \(error.localizedDescription)")
        }
    }
}
        func hideChartOptions() {
            chartOptionsStackView.isHidden = true
            optionsView.isHidden = false
        }
        @objc private func chartTypeSelected(_ gesture: UITapGestureRecognizer) {
            guard let selectedView = gesture.view as? ChartTypeOptionView,
                  let selectedType = VisualizationType.allCases.first(where: { $0.rawValue == selectedView.label.text }) else {
                return
            }
            chatBotManager.processUserSelection(selectedType.rawValue)
            updateUI()
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
                if options.isEmpty {
                    self?.optionsView.isHidden = true
                    self?.textInputView.isHidden = false
                    self?.sendButton.isHidden = false
                } else {
                    self?.optionsView.isHidden = false
                    self?.textInputView.isHidden = true
                    self?.sendButton.isHidden = true
                    self?.optionsView.options = options
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
                if options.isEmpty {
                    self?.optionsView.isHidden = true
                    self?.textInputView.isHidden = false
                    self?.sendButton.isHidden = false

                } else {
                    self?.optionsView.isHidden = false
                    self?.textInputView.isHidden = true
                    self?.sendButton.isHidden = true

                    self?.optionsView.options = options
                }
                let allowsMultipleSelection = self?.chatBotManager.allowsMultipleSelection() ?? true
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
extension ChatBotViewController {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if let name = textField.text, !name.isEmpty {
            chatBotManager.processUserSelection(name)
            updateChatWithUserOption(name)
        }
        textField.resignFirstResponder()
        return true
    }
}
