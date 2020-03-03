//import SoundWave

@objc(LKVoiceMessageView)
final class VoiceMessageView : UIView {
    private let voiceMessage: TSAttachment
    private let viewItem: ConversationViewItem
    private let style: ConversationStyle

    private lazy var isIncoming: Bool = {
        viewItem.interaction.interactionType() == .incomingMessage
    }()

    // MARK: Components
    private lazy var playbackButton: UIButton = {
        let result = UIButton()
        result.setImage(#imageLiteral(resourceName: "CirclePlay"), for: UIControl.State.normal)
        result.set(.width, to: 24)
        result.set(.height, to: 24)
        return result
    }()

    private lazy var progressView = ProgressView()

    private lazy var timeView: UILabel = {
        let result = UILabel()
        result.font = .systemFont(ofSize: Values.smallFontSize)
        result.textColor = Colors.text
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
        let leftView = UIView()
        leftView.addSubview(playbackButton)
        playbackButton.center(.horizontal, in: leftView)
        playbackButton.center(.vertical, in: leftView)
        leftView.addSubview(progressView)
        progressView.pin(to: leftView)
        leftView.set(.width, to: 36)
        leftView.set(.height, to: 36)
        let bundle = Bundle.main
        let url = bundle.url(forResource: "file_example_MP3_2MG", withExtension: "mp3")!
        let waveView = AudioVisualizationView()
        waveView.meteringLevelBarWidth = 2
        waveView.meteringLevelBarInterItem = 1
        waveView.meteringLevelBarSingleStick = true
        waveView.backgroundColor = .clear
        waveView.gradientStartColor = .white
        waveView.gradientEndColor = .white
        waveView.meteringLevelBarCornerRadius = 1
        waveView.stop()
        waveView.play(from: url)
        waveView.set(.height, to: 36)
//        waveformView.audioURL = url
//        waveformView.wavesColor = Colors.text
        let stackView = UIStackView(arrangedSubviews: [ leftView, waveView, timeView ])
        stackView.axis = .horizontal
        stackView.alignment = .center
        stackView.spacing = Values.mediumSpacing
        addSubview(stackView)
        stackView.pin(to: self)
    }

    // MARK: Updating
//    @objc func update() {
//        guard viewItem.attachmentPointer?.isDownloaded else { return }
//        self.voiceMessage.sourceFilename
//    }
}

// MARK: Progress View
final class ProgressView : UIView {

    private lazy var bottomLineLayer: CAShapeLayer = {
        let result = CAShapeLayer()
        result.lineWidth = 2
        result.strokeColor = Colors.separator.cgColor
        result.fillColor = UIColor.clear.cgColor
        return result
    }()

    private lazy var topLineLayer: CAShapeLayer = {
        let result = CAShapeLayer()
        result.lineWidth = 2
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

//        let path = UIBezierPath()
//        path.move(to: CGPoint(x: 0, y: h / 2))
//        let titleLabelFrame = titleLabel.frame.insetBy(dx: -10, dy: -6)
//        path.addLine(to: CGPoint(x: titleLabelFrame.origin.x, y: h / 2))
//        let oval = UIBezierPath(roundedRect: titleLabelFrame, cornerRadius: Values.separatorLabelHeight / 2)
//        path.append(oval)
//        path.move(to: CGPoint(x: titleLabelFrame.origin.x + titleLabelFrame.width, y: h / 2))
//        path.addLine(to: CGPoint(x: w, y: h / 2))
//        path.close()
//        lineLayer.path = path.cgPath
    }
}

//
//- (void)updateContents
//{
//    [self updateAudioProgressView];
//    [self updateAudioBottomLabel];
//
//    if (self.audioPlaybackState == AudioPlaybackState_Playing) {
//        [self setAudioIconToPause];
//    } else {
//        [self setAudioIconToPlay];
//    }
//}
//
//- (CGFloat)audioProgressSeconds
//{
//    return [self.viewItem audioProgressSeconds];
//}
//
//- (CGFloat)audioDurationSeconds
//{
//    return self.viewItem.audioDurationSeconds;
//}
//
//- (AudioPlaybackState)audioPlaybackState
//{
//    return [self.viewItem audioPlaybackState];
//}
//
//- (BOOL)isAudioPlaying
//{
//    return self.audioPlaybackState == AudioPlaybackState_Playing;
//}
//
//- (void)updateAudioBottomLabel
//{
//    if (self.isAudioPlaying && self.audioProgressSeconds > 0 && self.audioDurationSeconds > 0) {
//        self.audioBottomLabel.text =
//            [NSString stringWithFormat:@"%@ / %@",
//                      [OWSFormat formatDurationSeconds:(long)round(self.audioProgressSeconds)],
//                      [OWSFormat formatDurationSeconds:(long)round(self.audioDurationSeconds)]];
//    } else {
//        self.audioBottomLabel.text =
//            [NSString stringWithFormat:@"%@", [OWSFormat formatDurationSeconds:(long)round(self.audioDurationSeconds)]];
//    }
//}
//
//- (void)setAudioIcon:(UIImage *)icon
//{
//    icon = [icon resizedImageToSize:CGSizeMake(self.iconSize, self.iconSize)];
//    [_audioPlayPauseButton setImage:icon forState:UIControlStateNormal];
//    [_audioPlayPauseButton setImage:icon forState:UIControlStateDisabled];
//}
//
//- (void)setAudioIconToPlay
//{
//    [self setAudioIcon:[UIImage imageNamed:@"CirclePlay"]];
//}
//
//- (void)setAudioIconToPause
//{
//    [self setAudioIcon:[UIImage imageNamed:@"CirclePause"]];
//}
//
//- (void)updateAudioProgressView
//{
//    [self.audioProgressView
//        setProgress:(self.audioDurationSeconds > 0 ? self.audioProgressSeconds / self.audioDurationSeconds : 0.f)];
//
//    UIColor *progressColor = [self.conversationStyle bubbleSecondaryTextColorWithIsIncoming:self.isIncoming];
//    self.audioProgressView.horizontalBarColor = progressColor;
//    self.audioProgressView.progressColor = progressColor;
//}
//
//- (void)replaceIconWithDownloadProgressIfNecessary:(UIView *)iconView
//{
//    if (!self.viewItem.attachmentPointer) {
//        return;
//    }
//
//    switch (self.viewItem.attachmentPointer.state) {
//        case TSAttachmentPointerStateFailed:
//            // We don't need to handle the "tap to retry" state here,
//            // only download progress.
//            return;
//        case TSAttachmentPointerStateEnqueued:
//        case TSAttachmentPointerStateDownloading:
//            break;
//    }
//    switch (self.viewItem.attachmentPointer.pointerType) {
//        case TSAttachmentPointerTypeRestoring:
//            // TODO: Show "restoring" indicator and possibly progress.
//            return;
//        case TSAttachmentPointerTypeUnknown:
//        case TSAttachmentPointerTypeIncoming:
//            break;
//    }
//    NSString *_Nullable uniqueId = self.viewItem.attachmentPointer.uniqueId;
//    if (uniqueId.length < 1) {
//        OWSFailDebug(@"Missing uniqueId.");
//        return;
//    }
//
//    CGFloat downloadViewSize = self.iconSize;
//    MediaDownloadView *downloadView =
//        [[MediaDownloadView alloc] initWithAttachmentId:uniqueId radius:downloadViewSize * 0.5f];
//    iconView.layer.opacity = 0.01f;
//    [self addSubview:downloadView];
//    [downloadView autoSetDimensionsToSize:CGSizeMake(downloadViewSize, downloadViewSize)];
//    [downloadView autoAlignAxis:ALAxisHorizontal toSameAxisOfView:iconView];
//    [downloadView autoAlignAxis:ALAxisVertical toSameAxisOfView:iconView];
//}
//
//#pragma mark -
//
//- (CGFloat)hMargin
//{
//    return 0.f;
//}
//
//- (CGFloat)hSpacing
//{
//    return 8.f;
//}
//
//+ (CGFloat)vMargin
//{
//    return 0.f;
//}
//
//- (CGFloat)vMargin
//{
//    return [OWSAudioMessageView vMargin];
//}
//
//+ (CGFloat)bubbleHeight
//{
//    CGFloat iconHeight = self.iconSize;
//    CGFloat labelsHeight = ([OWSAudioMessageView labelFont].lineHeight * 2 +
//        [OWSAudioMessageView audioProgressViewHeight] + [OWSAudioMessageView labelVSpacing] * 2);
//    CGFloat contentHeight = MAX(iconHeight, labelsHeight);
//    return contentHeight + self.vMargin * 2;
//}
//
//- (CGFloat)bubbleHeight
//{
//    return [OWSAudioMessageView bubbleHeight];
//}
//
//+ (CGFloat)iconSize
//{
//    return 72.f;
//}
//
//- (CGFloat)iconSize
//{
//    return [OWSAudioMessageView iconSize];
//}
//
//- (BOOL)isVoiceMessage
//{
//    return self.attachment.isVoiceMessage;
//}
//
//- (void)createContents
//{
//    self.axis = UILayoutConstraintAxisHorizontal;
//    self.alignment = UIStackViewAlignmentCenter;
//    self.spacing = self.hSpacing;
//    self.layoutMarginsRelativeArrangement = YES;
//    self.layoutMargins = UIEdgeInsetsMake(self.vMargin, 0, self.vMargin, 0);
//
//    _audioPlayPauseButton = [UIButton buttonWithType:UIButtonTypeCustom];
//    self.audioPlayPauseButton.enabled = NO;
//    [self addArrangedSubview:self.audioPlayPauseButton];
//    self.audioPlayPauseButton.imageView.contentMode = UIViewContentModeCenter;
//    [self.audioPlayPauseButton autoSetDimension:ALDimensionWidth toSize:56.f];
//    [self.audioPlayPauseButton autoSetDimension:ALDimensionHeight toSize:56.f];
//    self.audioPlayPauseButton.imageView.clipsToBounds = NO;
//    self.audioPlayPauseButton.clipsToBounds = NO;
//    self.clipsToBounds = NO;
//
//    [self replaceIconWithDownloadProgressIfNecessary:self.audioPlayPauseButton];
//
//    NSString *_Nullable filename = self.attachment.sourceFilename;
//    if (filename.length < 1) {
//        filename = [self.attachmentStream.originalFilePath lastPathComponent];
//    }
//    NSString *topText = [[filename stringByDeletingPathExtension] ows_stripped];
//    if (topText.length < 1) {
//        topText = [MIMETypeUtil fileExtensionForMIMEType:self.attachment.contentType].localizedUppercaseString;
//    }
//    if (topText.length < 1) {
//        topText = NSLocalizedString(@"GENERIC_ATTACHMENT_LABEL", @"A label for generic attachments.");
//    }
//    if (self.isVoiceMessage) {
//        topText = nil;
//    }
//    UILabel *topLabel = [UILabel new];
//    topLabel.text = topText;
//    topLabel.textColor = [self.conversationStyle bubbleTextColorWithIsIncoming:self.isIncoming];
//    topLabel.lineBreakMode = NSLineBreakByTruncatingMiddle;
//    topLabel.font = [OWSAudioMessageView labelFont];
//
//    AudioProgressView *audioProgressView = [AudioProgressView new];
//    self.audioProgressView = audioProgressView;
//    [self updateAudioProgressView];
//    [audioProgressView autoSetDimension:ALDimensionHeight toSize:[OWSAudioMessageView audioProgressViewHeight]];
//
//    UILabel *bottomLabel = [UILabel new];
//    self.audioBottomLabel = bottomLabel;
//    [self updateAudioBottomLabel];
//    bottomLabel.textColor = [self.conversationStyle bubbleSecondaryTextColorWithIsIncoming:self.isIncoming];
//    bottomLabel.lineBreakMode = NSLineBreakByTruncatingMiddle;
//    bottomLabel.font = [OWSAudioMessageView labelFont];
//
//    UIStackView *labelsView = [UIStackView new];
//    labelsView.axis = UILayoutConstraintAxisVertical;
//    labelsView.spacing = [OWSAudioMessageView labelVSpacing];
//    [labelsView addArrangedSubview:topLabel];
//    [labelsView addArrangedSubview:audioProgressView];
//    [labelsView addArrangedSubview:bottomLabel];
//
//    // Ensure the "audio progress" and "play button" are v-center-aligned using a container.
//    UIView *labelsContainerView = [UIView containerView];
//    [self addArrangedSubview:labelsContainerView];
//    [labelsContainerView addSubview:labelsView];
//    [labelsView autoPinWidthToSuperview];
//    [labelsView autoPinEdgeToSuperviewMargin:ALEdgeTop relation:NSLayoutRelationGreaterThanOrEqual];
//    [labelsView autoPinEdgeToSuperviewMargin:ALEdgeBottom relation:NSLayoutRelationGreaterThanOrEqual];
//
//    [audioProgressView autoAlignAxis:ALAxisHorizontal toSameAxisOfView:self.audioPlayPauseButton];
//
//    [self updateContents];
//}
//
//+ (CGFloat)audioProgressViewHeight
//{
//    return 12.f;
//}
//
//+ (UIFont *)labelFont
//{
//    return [UIFont ows_dynamicTypeCaption2Font];
//}
//
//+ (CGFloat)labelVSpacing
//{
//    return 2.f;
//}
//
//@end
//
//NS_ASSUME_NONNULL_END
