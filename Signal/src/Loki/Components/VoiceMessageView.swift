import NVActivityIndicatorView

@objc(LKVoiceMessageView)
final class VoiceMessageView : UIView {
    private let voiceMessage: TSAttachment
    private let viewItem: ConversationViewItem
    private let style: ConversationStyle

    private lazy var isIncoming: Bool = {
        return viewItem.interaction.interactionType() == .incomingMessage
    }()
    
    private var isDownloading: Bool {
        guard let attachmentPointer = self.viewItem.attachmentPointer, attachmentPointer.uniqueId != nil else { return false }
        return attachmentPointer.state == .enqueued || attachmentPointer.state == .downloading
    }

    // MARK: Settings
    private static let contentHeight = CGFloat(40)
    
    private static func getVerticalMargin(for viewItem: ConversationViewItem) -> CGFloat {
        return viewItem.shouldHideFooter ? 0 : 4
    }
    
    @objc static func getHeight(for viewItem: ConversationViewItem) -> CGFloat {
        return contentHeight + 2 * getVerticalMargin(for: viewItem)
    }
    
    // MARK: Components
    private lazy var playbackButton: UIButton = {
        let result = UIButton()
        result.setImage(#imageLiteral(resourceName: "CirclePlay"), for: UIControl.State.normal)
        return result
    }()

    private lazy var progressView = ProgressView()

    private lazy var leftView: UIView = {
        let result = UIView()
        let size = VoiceMessageView.contentHeight
        result.set(.width, to: size)
        result.set(.height, to: size)
        return result
    }()
    
    private lazy var waveformView: AudioVisualizationView = {
        let result = AudioVisualizationView()
        result.meteringLevelBarWidth = 2
        result.meteringLevelBarInterItem = 1
        result.meteringLevelBarCornerRadius = 1
        result.meteringLevelBarSingleStick = true
        result.backgroundColor = .clear
        result.gradientStartColor = Colors.text
        result.gradientEndColor = Colors.text
        result.set(.height, to: VoiceMessageView.contentHeight)
        return result
    }()
    
    private lazy var spinner: NVActivityIndicatorView = {
        let result = NVActivityIndicatorView(frame: CGRect.zero, type: .ballPulse, color: Colors.text, padding: nil)
        result.set(.width, to: 24)
        result.set(.height, to: 24)
        return result
    }()
    
    private lazy var waveformViewContainer = UIView()
    
    private lazy var timeView: UILabel = {
        let result = UILabel()
        result.font = .systemFont(ofSize: Values.smallFontSize)
        result.textColor = Colors.text
        return result
    }()
    
    private lazy var stackView: UIStackView = {
        let result = UIStackView(arrangedSubviews: [ leftView, UIView.spacer(withWidth: 10), waveformViewContainer, UIView.spacer(withWidth: 8), timeView ])
        result.axis = .horizontal
        result.alignment = .center
        let verticalMargin = VoiceMessageView.getVerticalMargin(for: viewItem)
        result.layoutMargins = UIEdgeInsets(top: verticalMargin, left: 0, bottom: verticalMargin, right: 0)
        result.isLayoutMarginsRelativeArrangement = true
        return result
    }()

    // MARK: Initialization
    @objc init(voiceMessage: TSAttachment, viewItem: ConversationViewItem, style: ConversationStyle) {
        self.voiceMessage = voiceMessage
        self.viewItem = viewItem
        self.style = style
        super.init(frame: CGRect.zero)
        setUpViewHierarchy()
    }

    override init(frame: CGRect) {
        preconditionFailure("Use init(voiceMessage:viewItem:style:) instead.")
    }

    required init?(coder: NSCoder) {
        preconditionFailure("Use init(voiceMessage:viewItem:style:) instead.")
    }

    private func setUpViewHierarchy() {
        let leftViewInset = ProgressView.lineThickness / 2
        leftView.addSubview(playbackButton)
        playbackButton.pin(to: leftView, withInset: leftViewInset)
        leftView.addSubview(progressView)
        progressView.pin(to: leftView, withInset: leftViewInset)
        waveformViewContainer.addSubview(waveformView)
        waveformView.pin(to: waveformViewContainer)
        waveformViewContainer.addSubview(spinner)
        spinner.center(in: waveformViewContainer)
        timeView.text = OWSFormat.formatDurationSeconds(Int(viewItem.audioDurationSeconds))
        addSubview(stackView)
        stackView.pin(to: self)
    }
    
    // MARK: Updating
    @objc func update() {
        let verticalMargin = VoiceMessageView.getVerticalMargin(for: viewItem)
        stackView.layoutMargins = UIEdgeInsets(top: verticalMargin, left: 0, bottom: verticalMargin, right: 0)
        if isDownloading {
            waveformView.alpha = 0
            spinner.startAnimating()
        } else {
            if waveformView.alpha == 0 {
                UIView.animate(withDuration: 0.25) {
                    self.waveformView.alpha = 1
                }
            }
            let url = Bundle.main.url(forResource: "file_example_MP3_2MG", withExtension: "mp3")!
            waveformView.play(from: url)
            if spinner.alpha == 1 {
                UIView.animate(withDuration: 0.25) {
                    self.spinner.alpha = 0
                }
            }
            spinner.stopAnimating()
        }
    }
}

// MARK: Progress View
private final class ProgressView : UIView {

    static let lineThickness = CGFloat(2)
    
    private lazy var bottomLineLayer: CAShapeLayer = {
        let result = CAShapeLayer()
        result.lineWidth = ProgressView.lineThickness
        result.strokeColor = Colors.separator.cgColor
        result.fillColor = UIColor.clear.cgColor
        return result
    }()

    private lazy var topLineLayer: CAShapeLayer = {
        let result = CAShapeLayer()
        result.lineWidth = ProgressView.lineThickness
        result.strokeColor = Colors.accent.cgColor
        result.fillColor = UIColor.clear.cgColor
        return result
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setUpViewHierarchy()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setUpViewHierarchy()
    }

    private func setUpViewHierarchy() {
        layer.insertSublayer(bottomLineLayer, at: 0)
        layer.insertSublayer(topLineLayer, at: 1)
    }

    // MARK: Updating
    override func layoutSubviews() {
        super.layoutSubviews()
        updateLineLayer()
    }

    private func updateLineLayer() {
        let bottomPath = UIBezierPath(ovalIn: bounds)
        let fraction = CGFloat(0.75)
        let topPath = UIBezierPath(arcCenter: bounds.center, radius: width() / 2, startAngle: .pi, endAngle: .pi + fraction * 2 * .pi, clockwise: true)
        bottomLineLayer.path = bottomPath.cgPath
        topLineLayer.path = topPath.cgPath
    }
}
