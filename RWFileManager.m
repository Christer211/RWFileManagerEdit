#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <UniformTypeIdentifiers/UniformTypeIdentifiers.h>

// ─── Helpers ─────────────────────────────────────────────────────────────

static UIViewController *RWGetTopViewController(void) {
    UIWindowScene *scene = nil;
    for (UIWindowScene *s in [UIApplication sharedApplication].connectedScenes) {
        if ([s isKindOfClass:[UIWindowScene class]] &&
            s.activationState == UISceneActivationStateForegroundActive) {
            scene = s;
            break;
        }
    }
    UIWindow *key = scene.windows.firstObject;
    for (UIWindow *w in scene.windows) {
        if (w.isKeyWindow) { key = w; break; }
    }
    UIViewController *root = key.rootViewController;
    while (root.presentedViewController) {
        root = root.presentedViewController;
    }
    return root;
}

static NSString *RWFileSizeString(NSString *path, BOOL isDir) {
    if (isDir) return @"Folder";
    NSDictionary *a = [[NSFileManager defaultManager] attributesOfItemAtPath:path error:nil];
    unsigned long long b = [a[NSFileSize] unsignedLongLongValue];
    if (b < 1024)           return [NSString stringWithFormat:@"%llu B", b];
    if (b < 1024*1024)      return [NSString stringWithFormat:@"%.1f KB", b/1024.0];
    if (b < 1024*1024*1024) return [NSString stringWithFormat:@"%.1f MB", b/1024.0/1024.0];
    return [NSString stringWithFormat:@"%.1f GB", b/1024.0/1024.0/1024.0];
}

// ─── Custom Alert View Controller (replaces UIAlertController) ────────

@interface RWCustomAlertViewController : UIViewController
@property (nonatomic, copy) void (^buttonTapped)(NSInteger buttonIndex);
- (instancetype)initWithTitle:(NSString *)title message:(NSString *)message buttons:(NSArray<NSString *> *)buttonTitles;
@end

@implementation RWCustomAlertViewController {
    NSString *_titleText;
    NSString *_messageText;
    NSArray *_buttonTitles;
}

- (instancetype)initWithTitle:(NSString *)title message:(NSString *)message buttons:(NSArray<NSString *> *)buttonTitles {
    self = [super init];
    if (self) {
        _titleText = title;
        _messageText = message;
        _buttonTitles = buttonTitles;
        self.modalPresentationStyle = UIModalPresentationOverCurrentContext;
        self.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
        self.view.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.4];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    UIBlurEffect *blur = [UIBlurEffect effectWithStyle:UIBlurEffectStyleSystemMaterial];
    UIVisualEffectView *container = [[UIVisualEffectView alloc] initWithEffect:blur];
    container.layer.cornerRadius = 20;
    container.layer.cornerCurve = kCACornerCurveContinuous;
    container.clipsToBounds = YES;
    container.layer.borderWidth = 0.5;
    container.layer.borderColor = [UIColor separatorColor].CGColor;
    container.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:container];

    UIStackView *stack = [[UIStackView alloc] init];
    stack.axis = UILayoutConstraintAxisVertical;
    stack.spacing = 16;
    stack.alignment = UIStackViewAlignmentCenter;
    stack.translatesAutoresizingMaskIntoConstraints = NO;
    [container.contentView addSubview:stack];

    if (_titleText.length) {
        UILabel *titleLabel = [[UILabel alloc] init];
        titleLabel.text = _titleText;
        titleLabel.font = [UIFont systemFontOfSize:18 weight:UIFontWeightBold];
        titleLabel.textAlignment = NSTextAlignmentCenter;
        [stack addArrangedSubview:titleLabel];
    }

    if (_messageText.length) {
        UILabel *msgLabel = [[UILabel alloc] init];
        msgLabel.text = _messageText;
        msgLabel.font = [UIFont systemFontOfSize:14 weight:UIFontWeightRegular];
        msgLabel.textAlignment = NSTextAlignmentCenter;
        msgLabel.numberOfLines = 0;
        [stack addArrangedSubview:msgLabel];
    }

    UIStackView *buttonStack = [[UIStackView alloc] init];
    buttonStack.axis = UILayoutConstraintAxisHorizontal;
    buttonStack.spacing = 12;
    buttonStack.distribution = UIStackViewDistributionFillEqually;
    buttonStack.translatesAutoresizingMaskIntoConstraints = NO;
    [stack addArrangedSubview:buttonStack];

    for (NSInteger i = 0; i < _buttonTitles.count; i++) {
        UIButton *btn = [UIButton buttonWithType:UIButtonTypeSystem];
        [btn setTitle:_buttonTitles[i] forState:UIControlStateNormal];
        btn.titleLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightSemibold];
        btn.backgroundColor = (i == 0) ? [UIColor systemBlueColor] : [UIColor systemGray6Color];
        [btn setTitleColor:(i == 0) ? [UIColor whiteColor] : [UIColor labelColor] forState:UIControlStateNormal];
        btn.layer.cornerRadius = 10;
        btn.clipsToBounds = YES;
        btn.tag = i;
        [btn addTarget:self action:@selector(buttonAction:) forControlEvents:UIControlEventTouchUpInside];
        [buttonStack addArrangedSubview:btn];
    }

    [NSLayoutConstraint activateConstraints:@[
        [container.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
        [container.centerYAnchor constraintEqualToAnchor:self.view.centerYAnchor],
        [container.widthAnchor constraintEqualToConstant:280],
        [stack.topAnchor constraintEqualToAnchor:container.contentView.topAnchor constant:24],
        [stack.leadingAnchor constraintEqualToAnchor:container.contentView.leadingAnchor constant:20],
        [stack.trailingAnchor constraintEqualToAnchor:container.contentView.trailingAnchor constant:-20],
        [stack.bottomAnchor constraintEqualToAnchor:container.contentView.bottomAnchor constant:-24],
        [buttonStack.heightAnchor constraintEqualToConstant:44],
        [buttonStack.widthAnchor constraintEqualToAnchor:stack.widthAnchor],
    ]];
}

- (void)buttonAction:(UIButton *)sender {
    if (self.buttonTapped) self.buttonTapped(sender.tag);
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end

// ─── Glass Cell ─────────────────────────────────────────────────────────────

@interface RWGlassCell : UITableViewCell
- (void)configureWithName:(NSString *)name isDirectory:(BOOL)isDir detail:(NSString *)detail;
@end

@implementation RWGlassCell {
    UIVisualEffectView *_glass;
    UIImageView *_icon;
    UILabel *_nameLabel;
    UILabel *_detailLabel;
    UIImageView *_chevron;
}

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)rid {
    self = [super initWithStyle:UITableViewCellStyleDefault reuseIdentifier:rid];
    if (!self) return nil;
    self.backgroundColor = [UIColor clearColor];
    self.selectionStyle = UITableViewCellSelectionStyleNone;

    UIBlurEffect *blur = [UIBlurEffect effectWithStyle:UIBlurEffectStyleSystemThinMaterial];
    _glass = [[UIVisualEffectView alloc] initWithEffect:blur];
    _glass.layer.cornerRadius = 16;
    _glass.layer.cornerCurve = kCACornerCurveContinuous;
    _glass.clipsToBounds = YES;
    _glass.layer.borderWidth = 0.5;
    _glass.layer.borderColor = [UIColor separatorColor].CGColor;
    _glass.translatesAutoresizingMaskIntoConstraints = NO;
    [self.contentView addSubview:_glass];

    _icon = [[UIImageView alloc] init];
    _icon.contentMode = UIViewContentModeScaleAspectFit;
    _icon.translatesAutoresizingMaskIntoConstraints = NO;
    [_glass.contentView addSubview:_icon];

    _nameLabel = [[UILabel alloc] init];
    _nameLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightSemibold];
    _nameLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [_glass.contentView addSubview:_nameLabel];

    _detailLabel = [[UILabel alloc] init];
    _detailLabel.font = [UIFont systemFontOfSize:12 weight:UIFontWeightRegular];
    _detailLabel.textColor = [UIColor secondaryLabelColor];
    _detailLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [_glass.contentView addSubview:_detailLabel];

    UIImageSymbolConfiguration *cc = [UIImageSymbolConfiguration
        configurationWithPointSize:11 weight:UIImageSymbolWeightSemibold];
    _chevron = [[UIImageView alloc] initWithImage:[UIImage systemImageNamed:@"chevron.right" withConfiguration:cc]];
    _chevron.tintColor = [UIColor tertiaryLabelColor];
    _chevron.translatesAutoresizingMaskIntoConstraints = NO;
    [_glass.contentView addSubview:_chevron];

    UIView *cv = _glass.contentView;
    [NSLayoutConstraint activateConstraints:@[
        [_glass.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor constant:16],
        [_glass.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor constant:-16],
        [_glass.topAnchor constraintEqualToAnchor:self.contentView.topAnchor constant:4],
        [_glass.bottomAnchor constraintEqualToAnchor:self.contentView.bottomAnchor constant:-4],

        [_icon.leadingAnchor constraintEqualToAnchor:cv.leadingAnchor constant:14],
        [_icon.centerYAnchor constraintEqualToAnchor:cv.centerYAnchor],
        [_icon.widthAnchor constraintEqualToConstant:28],
        [_icon.heightAnchor constraintEqualToConstant:28],

        [_nameLabel.leadingAnchor constraintEqualToAnchor:_icon.trailingAnchor constant:12],
        [_nameLabel.trailingAnchor constraintEqualToAnchor:_chevron.leadingAnchor constant:-8],
        [_nameLabel.topAnchor constraintEqualToAnchor:cv.topAnchor constant:12],

        [_detailLabel.leadingAnchor constraintEqualToAnchor:_nameLabel.leadingAnchor],
        [_detailLabel.trailingAnchor constraintEqualToAnchor:_nameLabel.trailingAnchor],
        [_detailLabel.topAnchor constraintEqualToAnchor:_nameLabel.bottomAnchor constant:3],
        [_detailLabel.bottomAnchor constraintEqualToAnchor:cv.bottomAnchor constant:-12],

        [_chevron.trailingAnchor constraintEqualToAnchor:cv.trailingAnchor constant:-14],
        [_chevron.centerYAnchor constraintEqualToAnchor:cv.centerYAnchor],
        [_chevron.widthAnchor constraintEqualToConstant:9],
        [_chevron.heightAnchor constraintEqualToConstant:14],
    ]];
    return self;
}

- (void)configureWithName:(NSString *)name isDirectory:(BOOL)isDir detail:(NSString *)detail {
    _nameLabel.text = name;
    _detailLabel.text = detail;
    _chevron.hidden = !isDir;

    UIImageSymbolConfiguration *cfg = [UIImageSymbolConfiguration
        configurationWithPointSize:22 weight:UIImageSymbolWeightMedium];
    NSString *sym; UIColor *tint;
    if (isDir) {
        sym = @"folder.fill"; tint = [UIColor systemBlueColor];
    } else {
        NSString *ext = name.pathExtension.lowercaseString;
        if ([@[@"png",@"jpg",@"jpeg",@"heic",@"gif",@"webp"] containsObject:ext]) {
            sym = @"photo.fill"; tint = [UIColor systemGreenColor];
        } else if ([@[@"mp4",@"mov",@"mkv",@"avi",@"m4v"] containsObject:ext]) {
            sym = @"video.fill"; tint = [UIColor systemRedColor];
        } else if ([@[@"mp3",@"m4a",@"aac",@"wav",@"flac"] containsObject:ext]) {
            sym = @"music.note"; tint = [UIColor systemPinkColor];
        } else if ([ext isEqual:@"pdf"]) {
            sym = @"doc.richtext"; tint = [UIColor systemOrangeColor];
        } else if ([@[@"zip",@"rar",@"tar",@"gz",@"7z"] containsObject:ext]) {
            sym = @"archivebox.fill"; tint = [UIColor systemYellowColor];
        } else if ([@[@"ipa",@"deb",@"dylib",@"so"] containsObject:ext]) {
            sym = @"cube.fill"; tint = [UIColor systemPurpleColor];
        } else if ([@[@"txt",@"md",@"json",@"xml",@"plist",@"log",@"js",@"ts",
                       @"html",@"css",@"m",@"mm",@"h",@"c",@"cpp",@"swift",
                       @"py",@"rb",@"sh",@"bash",@"yaml",@"yml",@"conf",
                       @"cfg",@"ini",@"xm"] containsObject:ext]) {
            sym = @"doc.text.fill"; tint = [UIColor systemTealColor];
        } else {
            sym = @"doc.fill"; tint = [UIColor systemGrayColor];
        }
    }
    _icon.image = [UIImage systemImageNamed:sym withConfiguration:cfg];
    _icon.tintColor = tint;
}

- (void)setHighlighted:(BOOL)h animated:(BOOL)a {
    [super setHighlighted:h animated:a];
    [UIView animateWithDuration:h ? 0.12 : 0.25 delay:0
         usingSpringWithDamping:0.7 initialSpringVelocity:0
                        options:UIViewAnimationOptionAllowUserInteraction
                     animations:^{
        self->_glass.transform = h ? CGAffineTransformMakeScale(0.97, 0.97) : CGAffineTransformIdentity;
        self->_glass.alpha = h ? 0.75 : 1.0;
    } completion:nil];
}

@end

// ─── Text Editor ─────────────────────────────────────────────────────────────

@interface RWTextEditorViewController : UIViewController
@property (nonatomic, strong) NSString *filePath;
@end

@implementation RWTextEditorViewController {
    UITextView *_textView;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = self.filePath.lastPathComponent;
    self.navigationItem.largeTitleDisplayMode = UINavigationItemLargeTitleDisplayModeNever;
    self.view.backgroundColor = [UIColor systemGroupedBackgroundColor];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc]
        initWithBarButtonSystemItem:UIBarButtonSystemItemSave target:self action:@selector(save)];

    UIBlurEffect *blur = [UIBlurEffect effectWithStyle:UIBlurEffectStyleSystemMaterial];
    UIVisualEffectView *container = [[UIVisualEffectView alloc] initWithEffect:blur];
    container.layer.cornerRadius = 20;
    container.layer.cornerCurve = kCACornerCurveContinuous;
    container.clipsToBounds = YES;
    container.layer.borderWidth = 0.5;
    container.layer.borderColor = [UIColor separatorColor].CGColor;
    container.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:container];
    [NSLayoutConstraint activateConstraints:@[
        [container.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor constant:12],
        [container.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:16],
        [container.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-16],
        [container.bottomAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.bottomAnchor constant:-12],
    ]];

    _textView = [[UITextView alloc] init];
    _textView.font = [UIFont monospacedSystemFontOfSize:13 weight:UIFontWeightRegular];
    _textView.autocorrectionType = UITextAutocorrectionTypeNo;
    _textView.autocapitalizationType = UITextAutocapitalizationTypeNone;
    _textView.backgroundColor = [UIColor clearColor];
    _textView.textContainerInset = UIEdgeInsetsMake(16, 14, 16, 14);
    _textView.translatesAutoresizingMaskIntoConstraints = NO;
    [container.contentView addSubview:_textView];
    UIView *cv = container.contentView;
    [NSLayoutConstraint activateConstraints:@[
        [_textView.topAnchor constraintEqualToAnchor:cv.topAnchor],
        [_textView.leadingAnchor constraintEqualToAnchor:cv.leadingAnchor],
        [_textView.trailingAnchor constraintEqualToAnchor:cv.trailingAnchor],
        [_textView.bottomAnchor constraintEqualToAnchor:cv.bottomAnchor],
    ]];

    NSError *err;
    _textView.text = [NSString stringWithContentsOfFile:self.filePath
                                               encoding:NSUTF8StringEncoding error:&err] ?: @"";

    [[NSNotificationCenter defaultCenter] addObserver:self
        selector:@selector(keyboardChanged:) name:UIKeyboardWillChangeFrameNotification object:nil];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self
        name:UIKeyboardWillChangeFrameNotification object:nil];
}

- (void)keyboardChanged:(NSNotification *)note {
    CGRect kb = [note.userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue];
    CGFloat overlap = self.view.bounds.size.height - [self.view convertRect:kb fromView:nil].origin.y;
    UIEdgeInsets ins = UIEdgeInsetsMake(0, 0, MAX(overlap, 0), 0);
    _textView.contentInset = ins;
    _textView.scrollIndicatorInsets = ins;
}

- (void)save {
    NSError *err;
    BOOL ok = [_textView.text writeToFile:self.filePath atomically:YES
                                 encoding:NSUTF8StringEncoding error:&err];
    NSString *msg = ok ? @"Saved." : [NSString stringWithFormat:@"Error: %@", err.localizedDescription];
    // Use custom alert
    RWCustomAlertViewController *alert = [[RWCustomAlertViewController alloc] initWithTitle:nil message:msg buttons:@[@"OK"]];
    alert.buttonTapped = ^(NSInteger idx) {};
    [self presentViewController:alert animated:YES completion:nil];
}

@end

// ─── Custom Rename View ──────────────────────────────────────────────────

@interface RWRenameView : UIView
@property (nonatomic, copy) void (^renameBlock)(NSString *newName);
@property (nonatomic, copy) void (^cancelBlock)(void);
@property (nonatomic, strong) UITextField *textField;
- (instancetype)initWithOldName:(NSString *)oldName;
@end

@implementation RWRenameView {
    NSString *_oldName;
}

- (instancetype)initWithOldName:(NSString *)oldName {
    self = [super init];
    if (self) {
        _oldName = oldName;
        self.translatesAutoresizingMaskIntoConstraints = NO;

        UIBlurEffect *blur = [UIBlurEffect effectWithStyle:UIBlurEffectStyleSystemMaterial];
        UIVisualEffectView *container = [[UIVisualEffectView alloc] initWithEffect:blur];
        container.layer.cornerRadius = 20;
        container.layer.cornerCurve = kCACornerCurveContinuous;
        container.clipsToBounds = YES;
        container.layer.borderWidth = 0.5;
        container.layer.borderColor = [UIColor separatorColor].CGColor;
        container.translatesAutoresizingMaskIntoConstraints = NO;
        [self addSubview:container];

        UILabel *titleLabel = [[UILabel alloc] init];
        titleLabel.text = @"Rename";
        titleLabel.font = [UIFont systemFontOfSize:20 weight:UIFontWeightBold];
        titleLabel.textAlignment = NSTextAlignmentCenter;
        titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
        [container.contentView addSubview:titleLabel];

        _textField = [[UITextField alloc] init];
        _textField.text = _oldName;
        _textField.borderStyle = UITextBorderStyleRoundedRect;
        _textField.autocorrectionType = UITextAutocorrectionTypeNo;
        _textField.clearButtonMode = UITextFieldViewModeWhileEditing;
        _textField.returnKeyType = UIReturnKeyDone;
        _textField.translatesAutoresizingMaskIntoConstraints = NO;
        [container.contentView addSubview:_textField];

        UIStackView *buttonStack = [[UIStackView alloc] init];
        buttonStack.axis = UILayoutConstraintAxisHorizontal;
        buttonStack.spacing = 12;
        buttonStack.distribution = UIStackViewDistributionFillEqually;
        buttonStack.translatesAutoresizingMaskIntoConstraints = NO;
        [container.contentView addSubview:buttonStack];

        UIButton *cancelButton = [UIButton buttonWithType:UIButtonTypeSystem];
        [cancelButton setTitle:@"Cancel" forState:UIControlStateNormal];
        cancelButton.titleLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightMedium];
        cancelButton.backgroundColor = [UIColor systemGray6Color];
        cancelButton.layer.cornerRadius = 10;
        cancelButton.clipsToBounds = YES;
        [cancelButton addTarget:self action:@selector(cancelTapped) forControlEvents:UIControlEventTouchUpInside];

        UIButton *renameButton = [UIButton buttonWithType:UIButtonTypeSystem];
        [renameButton setTitle:@"Rename" forState:UIControlStateNormal];
        renameButton.titleLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightSemibold];
        renameButton.backgroundColor = [UIColor systemBlueColor];
        [renameButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        renameButton.layer.cornerRadius = 10;
        renameButton.clipsToBounds = YES;
        [renameButton addTarget:self action:@selector(renameTapped) forControlEvents:UIControlEventTouchUpInside];

        [buttonStack addArrangedSubview:cancelButton];
        [buttonStack addArrangedSubview:renameButton];

        [NSLayoutConstraint activateConstraints:@[
            [container.centerXAnchor constraintEqualToAnchor:self.centerXAnchor],
            [container.centerYAnchor constraintEqualToAnchor:self.centerYAnchor],
            [container.widthAnchor constraintEqualToConstant:320],
            [container.heightAnchor constraintGreaterThanOrEqualToConstant:200],

            [titleLabel.topAnchor constraintEqualToAnchor:container.contentView.topAnchor constant:20],
            [titleLabel.leadingAnchor constraintEqualToAnchor:container.contentView.leadingAnchor constant:20],
            [titleLabel.trailingAnchor constraintEqualToAnchor:container.contentView.trailingAnchor constant:-20],

            [_textField.topAnchor constraintEqualToAnchor:titleLabel.bottomAnchor constant:20],
            [_textField.leadingAnchor constraintEqualToAnchor:container.contentView.leadingAnchor constant:20],
            [_textField.trailingAnchor constraintEqualToAnchor:container.contentView.trailingAnchor constant:-20],
            [_textField.heightAnchor constraintEqualToConstant:44],

            [buttonStack.topAnchor constraintEqualToAnchor:_textField.bottomAnchor constant:20],
            [buttonStack.leadingAnchor constraintEqualToAnchor:container.contentView.leadingAnchor constant:20],
            [buttonStack.trailingAnchor constraintEqualToAnchor:container.contentView.trailingAnchor constant:-20],
            [buttonStack.bottomAnchor constraintEqualToAnchor:container.contentView.bottomAnchor constant:-20],
            [buttonStack.heightAnchor constraintEqualToConstant:44],
        ]];

        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self.textField becomeFirstResponder];
        });
    }
    return self;
}

- (void)cancelTapped {
    if (self.cancelBlock) self.cancelBlock();
}

- (void)renameTapped {
    NSString *newName = self.textField.text;
    if (self.renameBlock) self.renameBlock(newName);
}

@end

// ─── Custom Rename View Controller ──────────────────────────────────────

@interface RWRenameViewController : UIViewController
@property (nonatomic, copy) void (^renameBlock)(NSString *newName);
@property (nonatomic, copy) void (^cancelBlock)(void);
@property (nonatomic, strong) NSString *oldName;
@end

@implementation RWRenameViewController {
    RWRenameView *_renameView;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor clearColor];
    self.modalPresentationStyle = UIModalPresentationOverCurrentContext;
    self.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;

    _renameView = [[RWRenameView alloc] initWithOldName:self.oldName];
    _renameView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:_renameView];

    [NSLayoutConstraint activateConstraints:@[
        [_renameView.topAnchor constraintEqualToAnchor:self.view.topAnchor],
        [_renameView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [_renameView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [_renameView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],
    ]];

    __weak typeof(self) weakSelf = self;
    _renameView.renameBlock = ^(NSString *newName) {
        if (weakSelf.renameBlock) weakSelf.renameBlock(newName);
        [weakSelf dismissViewControllerAnimated:YES completion:nil];
    };
    _renameView.cancelBlock = ^{
        if (weakSelf.cancelBlock) weakSelf.cancelBlock();
        [weakSelf dismissViewControllerAnimated:YES completion:nil];
    };
}

@end

// ─── File Browser ─────────────────────────────────────────────────────────────

@interface RWFileBrowserViewController : UITableViewController <UIDocumentPickerDelegate>
@property (nonatomic, strong) NSString *directory;
@property (nonatomic, copy) NSArray<NSString *> *items;
@end

@implementation RWFileBrowserViewController

- (instancetype)init { return [super initWithStyle:UITableViewStylePlain]; }

- (void)viewDidLoad {
    [super viewDidLoad];
    if (!self.directory) self.directory = NSHomeDirectory();
    self.title = self.directory.lastPathComponent ?: @"Sandbox";
    self.navigationItem.largeTitleDisplayMode = UINavigationItemLargeTitleDisplayModeAlways;
    self.tableView.backgroundColor = [UIColor systemGroupedBackgroundColor];
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.contentInset = UIEdgeInsetsMake(4, 0, 20, 0);
    [self.tableView registerClass:[RWGlassCell class] forCellReuseIdentifier:@"glass"];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc]
        initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addTapped)];
    [self reload];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    if (self.navigationController.viewControllers.firstObject == self &&
        self.navigationController.presentingViewController != nil) {
        self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc]
            initWithBarButtonSystemItem:UIBarButtonSystemItemDone
            target:self action:@selector(dismissOverlay)];
    }
}

- (void)dismissOverlay {
    [self.navigationController.presentingViewController dismissViewControllerAnimated:YES completion:nil];
}

- (void)reload {
    NSError *err;
    NSArray *raw = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:self.directory error:&err];
    NSMutableArray *dirs = [NSMutableArray array], *files = [NSMutableArray array];
    for (NSString *n in raw) {
        BOOL isDir = NO;
        [[NSFileManager defaultManager] fileExistsAtPath:[self.directory stringByAppendingPathComponent:n]
                                             isDirectory:&isDir];
        if (isDir) [dirs addObject:n]; else [files addObject:n];
    }
    [dirs sortUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
    [files sortUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
    NSMutableArray *combined = [NSMutableArray arrayWithArray:dirs];
    [combined addObjectsFromArray:files];
    self.items = combined;
    [self.tableView reloadData];
}

- (NSInteger)tableView:(UITableView *)tv numberOfRowsInSection:(NSInteger)s { return self.items.count; }
- (CGFloat)tableView:(UITableView *)tv heightForRowAtIndexPath:(NSIndexPath *)ip { return 68; }

- (UITableViewCell *)tableView:(UITableView *)tv cellForRowAtIndexPath:(NSIndexPath *)ip {
    RWGlassCell *cell = [tv dequeueReusableCellWithIdentifier:@"glass" forIndexPath:ip];
    NSString *name = self.items[ip.row];
    NSString *full = [self.directory stringByAppendingPathComponent:name];
    BOOL isDir = NO;
    [[NSFileManager defaultManager] fileExistsAtPath:full isDirectory:&isDir];
    [cell configureWithName:name isDirectory:isDir detail:RWFileSizeString(full, isDir)];
    return cell;
}

- (void)tableView:(UITableView *)tv didSelectRowAtIndexPath:(NSIndexPath *)ip {
    [tv deselectRowAtIndexPath:ip animated:YES];
    NSString *full = [self.directory stringByAppendingPathComponent:self.items[ip.row]];
    BOOL isDir = NO;
    [[NSFileManager defaultManager] fileExistsAtPath:full isDirectory:&isDir];
    if (isDir) {
        RWFileBrowserViewController *sub = [RWFileBrowserViewController new];
        sub.directory = full;
        [self.navigationController pushViewController:sub animated:YES];
    } else {
        [self openFile:full];
    }
}

- (void)openFile:(NSString *)path {
    NSSet *textExts = [NSSet setWithArray:@[@"txt",@"md",@"json",@"xml",@"plist",@"log",
        @"js",@"ts",@"html",@"css",@"m",@"mm",@"h",@"c",@"cpp",@"swift",
        @"py",@"rb",@"sh",@"bash",@"yaml",@"yml",@"conf",@"cfg",@"ini",@"xm"]];
    if ([textExts containsObject:path.pathExtension.lowercaseString]) {
        RWTextEditorViewController *ed = [RWTextEditorViewController new];
        ed.filePath = path;
        [self.navigationController pushViewController:ed animated:YES];
    } else {
        UIActivityViewController *ac = [[UIActivityViewController alloc]
            initWithActivityItems:@[[NSURL fileURLWithPath:path]] applicationActivities:nil];
        ac.popoverPresentationController.barButtonItem = self.navigationItem.rightBarButtonItem;
        [self presentViewController:ac animated:YES completion:nil];
    }
}

// Long press → open in text editor
- (void)tableView:(UITableView *)tv willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)ip {
    for (UIGestureRecognizer *gr in cell.gestureRecognizers.copy) {
        if ([gr isKindOfClass:[UILongPressGestureRecognizer class]])
            [cell removeGestureRecognizer:gr];
    }
    UILongPressGestureRecognizer *lp = [[UILongPressGestureRecognizer alloc]
        initWithTarget:self action:@selector(handleLongPress:)];
    lp.minimumPressDuration = 0.5;
    [cell addGestureRecognizer:lp];
    cell.tag = ip.row;
}

- (void)handleLongPress:(UILongPressGestureRecognizer *)gr {
    if (gr.state != UIGestureRecognizerStateBegan) return;
    NSInteger row = gr.view.tag;
    if (row >= (NSInteger)self.items.count) return;
    NSString *full = [self.directory stringByAppendingPathComponent:self.items[row]];
    BOOL isDir = NO;
    [[NSFileManager defaultManager] fileExistsAtPath:full isDirectory:&isDir];
    if (isDir) return;
    RWTextEditorViewController *ed = [RWTextEditorViewController new];
    ed.filePath = full;
    [self.navigationController pushViewController:ed animated:YES];
}

// ─── SWIPE LEFT → DELETE ──────────────────────────────────────────────────
- (UISwipeActionsConfiguration *)tableView:(UITableView *)tv
trailingSwipeActionsConfigurationForRowAtIndexPath:(NSIndexPath *)ip {
    NSString *full = [self.directory stringByAppendingPathComponent:self.items[ip.row]];
    UIContextualAction *del = [UIContextualAction
        contextualActionWithStyle:UIContextualActionStyleDestructive title:nil
        handler:^(UIContextualAction *a, UIView *sv, void(^done)(BOOL)) {
            [[NSFileManager defaultManager] removeItemAtPath:full error:nil];
            [self reload]; done(YES);
        }];
    del.image = [UIImage systemImageNamed:@"trash.fill"];
    return [UISwipeActionsConfiguration configurationWithActions:@[del]];
}

// ─── SWIPE RIGHT → RENAME (MODAL CUSTOM VC) ─────────────────────────────
- (UISwipeActionsConfiguration *)tableView:(UITableView *)tv
leadingSwipeActionsConfigurationForRowAtIndexPath:(NSIndexPath *)ip {
    NSString *oldName = self.items[ip.row];
    NSString *oldPath = [self.directory stringByAppendingPathComponent:oldName];
    __weak typeof(self) weakSelf = self;

    UIContextualAction *renameAction = [UIContextualAction
        contextualActionWithStyle:UIContextualActionStyleNormal title:nil
        handler:^(UIContextualAction *action, UIView *sv, void(^done)(BOOL)) {
            done(YES);

            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)),
                           dispatch_get_main_queue(), ^{
                __strong typeof(weakSelf) strongSelf = weakSelf;
                if (!strongSelf) return;

                UIViewController *presenter = RWGetTopViewController();
                if (!presenter) return;

                RWRenameViewController *renameVC = [RWRenameViewController new];
                renameVC.oldName = oldName;

                renameVC.renameBlock = ^(NSString *newName) {
                    if (newName.length && ![newName isEqualToString:oldName] &&
                        ![newName containsString:@"/"]) {
                        NSString *newPath = [strongSelf.directory stringByAppendingPathComponent:newName];
                        [[NSFileManager defaultManager] moveItemAtPath:oldPath toPath:newPath error:nil];
                        [strongSelf reload];
                    }
                };

                renameVC.cancelBlock = ^{
                    // Nothing
                };

                [presenter presentViewController:renameVC animated:YES completion:nil];
            });
        }];

    renameAction.image = [UIImage systemImageNamed:@"pencil"];
    renameAction.backgroundColor = [UIColor systemBlueColor];
    return [UISwipeActionsConfiguration configurationWithActions:@[renameAction]];
}

// ─── ADD BUTTON (Custom Action Sheet) ───────────────────────────────────
- (void)addTapped {
    RWCustomAlertViewController *alert = [[RWCustomAlertViewController alloc]
        initWithTitle:@"Add" message:nil buttons:@[@"New Folder", @"Import File", @"Cancel"]];
    __weak typeof(self) weakSelf = self;
    alert.buttonTapped = ^(NSInteger idx) {
        if (idx == 0) {
            [weakSelf createNewFolder];
        } else if (idx == 1) {
            [weakSelf importFile];
        }
        // idx == 2 -> Cancel, do nothing
    };
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)createNewFolder {
    NSFileManager *fm = [NSFileManager defaultManager];
    NSString *base = @"New Folder";
    NSString *name = base;
    NSInteger n = 2;
    while ([fm fileExistsAtPath:[self.directory stringByAppendingPathComponent:name]]) {
        name = [NSString stringWithFormat:@"%@ %ld", base, (long)n];
        n++;
    }
    NSString *path = [self.directory stringByAppendingPathComponent:name];
    [fm createDirectoryAtPath:path withIntermediateDirectories:NO attributes:nil error:nil];
    [self reload];
}

- (void)importFile {
    UIDocumentPickerViewController *picker;
    if (@available(iOS 14.0, *)) {
        picker = [[UIDocumentPickerViewController alloc]
            initForOpeningContentTypes:@[UTTypeItem] asCopy:YES];
    } else {
        picker = [[UIDocumentPickerViewController alloc]
            initWithDocumentTypes:@[@"public.item"] inMode:UIDocumentPickerModeImport];
    }
    picker.delegate = self;
    picker.allowsMultipleSelection = YES;
    [self presentViewController:picker animated:YES completion:nil];
}

- (void)documentPicker:(UIDocumentPickerViewController *)controller
didPickDocumentsAtURLs:(NSArray<NSURL *> *)urls {
    for (NSURL *url in urls) {
        [url startAccessingSecurityScopedResource];
        NSString *dest = [self.directory stringByAppendingPathComponent:url.lastPathComponent];
        [[NSFileManager defaultManager] copyItemAtPath:url.path toPath:dest error:nil];
        [url stopAccessingSecurityScopedResource];
    }
    [self reload];
}

@end

// ─── Overlay ──────────────────────────────────────────────────────────────────

@interface RWOverlayViewController : UIViewController
@end

@implementation RWOverlayViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [[UIColor systemGroupedBackgroundColor] colorWithAlphaComponent:0.85];

    UIBlurEffect *blur = [UIBlurEffect effectWithStyle:UIBlurEffectStyleSystemMaterial];
    UIVisualEffectView *bg = [[UIVisualEffectView alloc] initWithEffect:blur];
    bg.frame = self.view.bounds;
    bg.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.view insertSubview:bg atIndex:0];

    RWFileBrowserViewController *browser = [RWFileBrowserViewController new];
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:browser];
    nav.navigationBar.prefersLargeTitles = YES;
    nav.view.backgroundColor = [UIColor clearColor];

    UINavigationBarAppearance *app = [[UINavigationBarAppearance alloc] init];
    [app configureWithDefaultBackground];
    app.backgroundEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleSystemUltraThinMaterial];
    app.backgroundColor = [[UIColor systemBackgroundColor] colorWithAlphaComponent:0.01];
    app.shadowColor = [UIColor clearColor];
    nav.navigationBar.standardAppearance = app;
    nav.navigationBar.scrollEdgeAppearance = app;
    if (@available(iOS 15.0, *)) nav.navigationBar.compactScrollEdgeAppearance = app;
    nav.navigationBar.translucent = YES;

    [self addChildViewController:nav];
    nav.view.frame = self.view.bounds;
    nav.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.view addSubview:nav.view];
    [nav didMoveToParentViewController:self];
}

@end

// ─── Constructor ──────────────────────────────────────────────────────────────

static void presentFileManager(void) {
    dispatch_async(dispatch_get_main_queue(), ^{
        UIViewController *topVC = RWGetTopViewController();
        if (!topVC) return;

        RWOverlayViewController *overlay = [RWOverlayViewController new];
        if (@available(iOS 15.0, *)) {
            overlay.modalPresentationStyle = UIModalPresentationPageSheet;
            UISheetPresentationController *sheet = overlay.sheetPresentationController;
            sheet.detents = @[UISheetPresentationControllerDetent.largeDetent];
            sheet.prefersGrabberVisible = YES;
            sheet.preferredCornerRadius = 28;
        } else {
            overlay.modalPresentationStyle = UIModalPresentationFullScreen;
        }
        [topVC presentViewController:overlay animated:YES completion:nil];
    });
}

__attribute__((constructor))
static void RWFileManagerInit(void) {
    [[NSNotificationCenter defaultCenter]
        addObserverForName:UIApplicationUserDidTakeScreenshotNotification
        object:nil queue:[NSOperationQueue mainQueue]
        usingBlock:^(NSNotification *n) { presentFileManager(); }];
}