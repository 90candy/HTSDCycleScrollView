//
//  YWSDCycleScrollView.m
//  YWSDCycleScrollView
//
//  Created by aier on 15-3-22.
//  Copyright (c) 2015年 GSD. All rights reserved.
//

/*
 
 *********************************************************************************
 *
 * 🌟🌟🌟 新建YWSDCycleScrollView交流QQ群：185534916 🌟🌟🌟
 *
 * 在您使用此自动轮播库的过程中如果出现bug请及时以以下任意一种方式联系我们，我们会及时修复bug并
 * 帮您解决问题。
 * 新浪微博:GSD_iOS
 * Email : gsdios@126.com
 * GitHub: https://github.com/gsdios
 *
 * 另（我的自动布局库SDAutoLayout）：
 *  一行代码搞定自动布局！支持Cell和Tableview高度自适应，Label和ScrollView内容自适应，致力于
 *  做最简单易用的AutoLayout库。
 * 视频教程：http://www.letv.com/ptv/vplay/24038772.html
 * 用法示例：https://github.com/gsdios/SDAutoLayout/blob/master/README.md
 * GitHub：https://github.com/gsdios/SDAutoLayout
 *********************************************************************************
 
 */


#import "YWSDCycleScrollView.h"
#import "UIView+YWSDExtension.h"
#import "YWTAPageControl.h"
#import "UIImageView+WebCache.h"
#import "SDImageCache.h"

#define kCycleScrollViewInitialPageControlDotSize CGSizeMake(10, 10)

NSString * const ID = @"cycleCell";

@interface YWSDCycleScrollView () <UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout>

@property (nonatomic, weak) UICollectionViewFlowLayout *flowLayout;
@property (nonatomic, strong) NSArray *imagePathsGroup;
@property (nonatomic, weak) NSTimer *timer;
@property (nonatomic, assign) NSInteger totalItemsCount;
@property (nonatomic, weak) UIControl *pageControl;

@property (nonatomic, strong) UIImageView *backgroundImageView; // 当imageURLs为空时的背景图

@property (assign, nonatomic) CGFloat contentOffsetX;  // collectionView偏移量

@end

@implementation YWSDCycleScrollView

- (instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        _maxHeight = frame.size.height;
        _minHeight = _maxHeight * 0.9;
        [self initialization];
        [self setupMainView];
    }
    return self;
}

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    [self initialization];
    [self setupMainView];
}

- (void)initialization
{
    _pageControlAliment = YWSDCycleScrollViewPageContolAlimentCenter;
    _autoScrollTimeInterval = 5.0;
    _titleLabelTextColor = [UIColor blackColor];
    _titleLabelTextFont= [UIFont systemFontOfSize:14];
    _titleLabelBackgroundColor = [UIColor clearColor];
    _titleLabelHeight = 30;
    _autoScroll = YES;
    _infiniteLoop = YES;
    _showPageControl = YES;
    _pageControlDotSize = kCycleScrollViewInitialPageControlDotSize;
    _pageControlBottomOffset = 0;
    _pageControlRightOffset = 0;
    _pageControlStyle = YWSDCycleScrollViewPageContolStyleClassic;
    _hidesForSinglePage = YES;
    _currentPageDotColor = [UIColor whiteColor];
    _pageDotColor = [UIColor lightGrayColor];
    _bannerImageViewContentMode = UIViewContentModeScaleToFill;
    
    self.backgroundColor = [UIColor clearColor];
    self.contentOffsetX = 0;
}

+ (instancetype)cycleScrollViewWithFrame:(CGRect)frame imageNamesGroup:(NSArray *)imageNamesGroup
{
    YWSDCycleScrollView *cycleScrollView = [[self alloc] initWithFrame:frame];
    cycleScrollView.localizationImageNamesGroup = [NSMutableArray arrayWithArray:imageNamesGroup];
    return cycleScrollView;
}

+ (instancetype)cycleScrollViewWithFrame:(CGRect)frame shouldInfiniteLoop:(BOOL)infiniteLoop imageNamesGroup:(NSArray *)imageNamesGroup
{
    YWSDCycleScrollView *cycleScrollView = [[self alloc] initWithFrame:frame];
    cycleScrollView.infiniteLoop = infiniteLoop;
    cycleScrollView.localizationImageNamesGroup = [NSMutableArray arrayWithArray:imageNamesGroup];
    return cycleScrollView;
}

+ (instancetype)cycleScrollViewWithFrame:(CGRect)frame imageURLStringsGroup:(NSArray *)imageURLsGroup
{
    YWSDCycleScrollView *cycleScrollView = [[self alloc] initWithFrame:frame];
    cycleScrollView.imageURLStringsGroup = [NSMutableArray arrayWithArray:imageURLsGroup];
    return cycleScrollView;
}

+ (instancetype)cycleScrollViewWithFrame:(CGRect)frame delegate:(id<YWSDCycleScrollViewDelegate>)delegate placeholderImage:(UIImage *)placeholderImage
{
    YWSDCycleScrollView *cycleScrollView = [[self alloc] initWithFrame:frame];
    cycleScrollView.delegate = delegate;
    cycleScrollView.placeholderImage = placeholderImage;
    
    return cycleScrollView;
}

// 设置显示图片的collectionView
- (void)setupMainView
{
    UICollectionViewFlowLayout *flowLayout = [[UICollectionViewFlowLayout alloc] init];
    flowLayout.minimumLineSpacing = 0;
    flowLayout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
    _flowLayout = flowLayout;
    
    UICollectionView *mainView = [[UICollectionView alloc] initWithFrame:self.bounds collectionViewLayout:flowLayout];
    mainView.backgroundColor = [UIColor clearColor];
    mainView.pagingEnabled = YES;
    mainView.showsHorizontalScrollIndicator = NO;
    mainView.showsVerticalScrollIndicator = NO;
    [mainView registerClass:[YWSDCollectionViewCell class] forCellWithReuseIdentifier:ID];
    mainView.dataSource = self;
    mainView.delegate = self;
    mainView.scrollsToTop = NO;
    [self addSubview:mainView];
    _mainView = mainView;
}


#pragma mark - properties

- (void)setDelegate:(id<YWSDCycleScrollViewDelegate>)delegate
{
    _delegate = delegate;
    
    if ([self.delegate respondsToSelector:@selector(customCollectionViewCellClassForCycleScrollView:)] && [self.delegate customCollectionViewCellClassForCycleScrollView:self]) {
        [self.mainView registerClass:[self.delegate customCollectionViewCellClassForCycleScrollView:self] forCellWithReuseIdentifier:ID];
    }else if ([self.delegate respondsToSelector:@selector(customCollectionViewCellNibForCycleScrollView:)] && [self.delegate customCollectionViewCellNibForCycleScrollView:self]) {
        [self.mainView registerNib:[self.delegate customCollectionViewCellNibForCycleScrollView:self] forCellWithReuseIdentifier:ID];
    }
}


- (void)setPlaceholderImage:(UIImage *)placeholderImage
{
    _placeholderImage = placeholderImage;
    
    if (!self.backgroundImageView) {
        UIImageView *bgImageView = [UIImageView new];
        bgImageView.contentMode = UIViewContentModeScaleAspectFit;
        [self insertSubview:bgImageView belowSubview:self.mainView];
        self.backgroundImageView = bgImageView;
    }
    
    self.backgroundImageView.image = placeholderImage;
}

- (void)setPageControlDotSize:(CGSize)pageControlDotSize
{
    _pageControlDotSize = pageControlDotSize;
    [self setupPageControl];
    if ([self.pageControl isKindOfClass:[YWTAPageControl class]]) {
        YWTAPageControl *pageContol = (YWTAPageControl *)_pageControl;
        pageContol.dotSize = pageControlDotSize;
    }
}

- (void)setShowPageControl:(BOOL)showPageControl
{
    _showPageControl = showPageControl;
    
    _pageControl.hidden = !showPageControl;
}

- (void)setCurrentPageDotColor:(UIColor *)currentPageDotColor
{
    _currentPageDotColor = currentPageDotColor;
    if ([self.pageControl isKindOfClass:[YWTAPageControl class]]) {
        YWTAPageControl *pageControl = (YWTAPageControl *)_pageControl;
        pageControl.dotColor = currentPageDotColor;
    } else {
        UIPageControl *pageControl = (UIPageControl *)_pageControl;
        pageControl.currentPageIndicatorTintColor = currentPageDotColor;
    }
    
}

- (void)setPageDotColor:(UIColor *)pageDotColor
{
    _pageDotColor = pageDotColor;
    
    if ([self.pageControl isKindOfClass:[UIPageControl class]]) {
        UIPageControl *pageControl = (UIPageControl *)_pageControl;
        pageControl.pageIndicatorTintColor = pageDotColor;
    }
}

- (void)setCurrentPageDotImage:(UIImage *)currentPageDotImage
{
    _currentPageDotImage = currentPageDotImage;
    
    if (self.pageControlStyle != YWSDCycleScrollViewPageContolStyleAnimated) {
        self.pageControlStyle = YWSDCycleScrollViewPageContolStyleAnimated;
    }
    
    [self setCustomPageControlDotImage:currentPageDotImage isCurrentPageDot:YES];
}

- (void)setPageDotImage:(UIImage *)pageDotImage
{
    _pageDotImage = pageDotImage;
    
    if (self.pageControlStyle != YWSDCycleScrollViewPageContolStyleAnimated) {
        self.pageControlStyle = YWSDCycleScrollViewPageContolStyleAnimated;
    }
    
    [self setCustomPageControlDotImage:pageDotImage isCurrentPageDot:NO];
}

- (void)setCustomPageControlDotImage:(UIImage *)image isCurrentPageDot:(BOOL)isCurrentPageDot
{
    if (!image || !self.pageControl) return;
    
    if ([self.pageControl isKindOfClass:[YWTAPageControl class]]) {
        YWTAPageControl *pageControl = (YWTAPageControl *)_pageControl;
        if (isCurrentPageDot) {
            pageControl.currentDotImage = image;
        } else {
            pageControl.dotImage = image;
        }
    }
}

- (void)setInfiniteLoop:(BOOL)infiniteLoop
{
    _infiniteLoop = infiniteLoop;
    
    if (self.imagePathsGroup.count) {
        self.imagePathsGroup = self.imagePathsGroup;
    }
}

-(void)setAutoScroll:(BOOL)autoScroll{
    _autoScroll = autoScroll;
    
    [self invalidateTimer];
    
    if (_autoScroll) {
        [self setupTimer];
    }
}

- (void)setScrollDirection:(UICollectionViewScrollDirection)scrollDirection
{
    _scrollDirection = scrollDirection;
    
    _flowLayout.scrollDirection = scrollDirection;
}

- (void)setAutoScrollTimeInterval:(CGFloat)autoScrollTimeInterval
{
    _autoScrollTimeInterval = autoScrollTimeInterval;
    
    [self setAutoScroll:self.autoScroll];
}

- (void)setPageControlStyle:(YWSDCycleScrollViewPageContolStyle)pageControlStyle
{
    _pageControlStyle = pageControlStyle;
    
    [self setupPageControl];
}

- (void)setImagePathsGroup:(NSArray *)imagePathsGroup
{
    [self invalidateTimer];
    
    _imagePathsGroup = imagePathsGroup;
    
    _totalItemsCount = self.infiniteLoop ? self.imagePathsGroup.count * 100 : self.imagePathsGroup.count;
    
    if (imagePathsGroup.count != 1) {
        self.mainView.scrollEnabled = YES;
        [self setAutoScroll:self.autoScroll];
    } else {
        self.mainView.scrollEnabled = NO;
    }
    
    [self setupPageControl];
    [self.mainView reloadData];
}

- (void)setImageURLStringsGroup:(NSArray *)imageURLStringsGroup
{
    _imageURLStringsGroup = imageURLStringsGroup;
    
    NSMutableArray *temp = [NSMutableArray new];
    [_imageURLStringsGroup enumerateObjectsUsingBlock:^(NSString * obj, NSUInteger idx, BOOL * stop) {
        NSString *urlString;
        if ([obj isKindOfClass:[NSString class]]) {
            urlString = obj;
        } else if ([obj isKindOfClass:[NSURL class]]) {
            NSURL *url = (NSURL *)obj;
            urlString = [url absoluteString];
        }
        if (urlString) {
            [temp addObject:urlString];
        }
    }];
    self.imagePathsGroup = [temp copy];
}

- (void)setLocalizationImageNamesGroup:(NSArray *)localizationImageNamesGroup
{
    _localizationImageNamesGroup = localizationImageNamesGroup;
    self.imagePathsGroup = [localizationImageNamesGroup copy];
}

- (void)setTitlesGroup:(NSArray *)titlesGroup
{
    _titlesGroup = titlesGroup;
    if (self.onlyDisplayText) {
        NSMutableArray *temp = [NSMutableArray new];
        for (int i = 0; i < _titlesGroup.count; i++) {
            [temp addObject:@""];
        }
//        self.backgroundColor = [UIColor clearColor];
        self.imageURLStringsGroup = [temp copy];
    }
}

#pragma mark - actions

- (void)setupTimer
{
    NSTimer *timer = [NSTimer scheduledTimerWithTimeInterval:self.autoScrollTimeInterval target:self selector:@selector(automaticScroll) userInfo:nil repeats:YES];
    _timer = timer;
    [[NSRunLoop mainRunLoop] addTimer:timer forMode:NSRunLoopCommonModes];
}

- (void)invalidateTimer
{
    [_timer invalidate];
    _timer = nil;
}

- (void)setupPageControl
{
    if (_pageControl) [_pageControl removeFromSuperview]; // 重新加载数据时调整
    
    if (self.imagePathsGroup.count == 0 || self.onlyDisplayText) return;
    
    if ((self.imagePathsGroup.count == 1) && self.hidesForSinglePage) return;
    
    int indexOnPageControl = [self pageControlIndexWithCurrentCellIndex:[self currentIndex]];
    
    switch (self.pageControlStyle) {
        case YWSDCycleScrollViewPageContolStyleAnimated:
        {
            YWTAPageControl *pageControl = [[YWTAPageControl alloc] init];
            pageControl.numberOfPages = self.imagePathsGroup.count;
            pageControl.dotColor = self.currentPageDotColor;
            pageControl.normalColor = self.pageDotColor;
            pageControl.userInteractionEnabled = NO;
            pageControl.currentPage = indexOnPageControl;
            [self addSubview:pageControl];
            _pageControl = pageControl;
        }
            break;
            
        case YWSDCycleScrollViewPageContolStyleClassic:
        {
            UIPageControl *pageControl = [[UIPageControl alloc] init];
            pageControl.numberOfPages = self.imagePathsGroup.count;
            pageControl.currentPageIndicatorTintColor = self.currentPageDotColor;
            pageControl.pageIndicatorTintColor = self.pageDotColor;
            pageControl.userInteractionEnabled = NO;
            pageControl.currentPage = indexOnPageControl;
            [self addSubview:pageControl];
            _pageControl = pageControl;
        }
            break;
            
        default:
            break;
    }
    
    // 重设pagecontroldot图片
    if (self.currentPageDotImage) {
        self.currentPageDotImage = self.currentPageDotImage;
    }
    if (self.pageDotImage) {
        self.pageDotImage = self.pageDotImage;
    }
}


- (void)automaticScroll
{
    if (0 == _totalItemsCount) return;
    int currentIndex = [self currentIndex];
    int targetIndex = currentIndex + 1;
    [self scrollToIndex:targetIndex];
}

- (void)scrollToIndex:(int)targetIndex
{
    UICollectionViewScrollPosition scrollPosition;
    if (self.scrollDirection == UICollectionViewScrollDirectionHorizontal) {
        scrollPosition = UICollectionViewScrollPositionCenteredHorizontally;
    } else {
        scrollPosition = UICollectionViewScrollPositionCenteredVertically;
    }
    
    if (targetIndex >= _totalItemsCount) {
        if (self.infiniteLoop) {
            targetIndex = _totalItemsCount * 0.5;
            [_mainView scrollToItemAtIndexPath:[NSIndexPath indexPathForItem:targetIndex inSection:0] atScrollPosition:scrollPosition animated:NO];
        }
        return;
    }
    [_mainView scrollToItemAtIndexPath:[NSIndexPath indexPathForItem:targetIndex inSection:0] atScrollPosition:scrollPosition animated:YES];
}

- (int)currentIndex
{
    if (_mainView.sd_width == 0 || _mainView.sd_height == 0) {
        return 0;
    }
    
    int index = 0;
    if (_flowLayout.scrollDirection == UICollectionViewScrollDirectionHorizontal) {
        index = (_mainView.contentOffset.x + _flowLayout.itemSize.width * 0.5) / _flowLayout.itemSize.width;
    } else {
        index = (_mainView.contentOffset.y + _flowLayout.itemSize.height * 0.5) / _flowLayout.itemSize.height;
    }
    
    return MAX(0, index);
}

- (int)pageControlIndexWithCurrentCellIndex:(NSInteger)index
{
    return (int)index % self.imagePathsGroup.count;
}

- (void)clearCache
{
    [[self class] clearImagesCache];
}

+ (void)clearImagesCache
{
    [[[SDWebImageManager sharedManager] imageCache] clearDiskOnCompletion:^{}];
}

#pragma mark - life circles

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    if (!self.zoomType) {
        _flowLayout.itemSize = self.frame.size;
    } else {
        _flowLayout.itemSize = CGSizeMake(YWMaxWidth, _maxHeight);
    }
    
    _mainView.frame = self.bounds;
    
    if (_mainView.contentOffset.x == 0 &&  _totalItemsCount) {
        int targetIndex = 0;
        if (self.infiniteLoop) {
            targetIndex = _totalItemsCount * 0.5;
        }else{
            targetIndex = 0;
        }
        
        UICollectionViewScrollPosition scrollPosition;
        if (self.scrollDirection == UICollectionViewScrollDirectionHorizontal) {
            scrollPosition = UICollectionViewScrollPositionCenteredHorizontally;
        } else {
            scrollPosition = UICollectionViewScrollPositionCenteredVertically;
        }
        
        [_mainView scrollToItemAtIndexPath:[NSIndexPath indexPathForItem:targetIndex inSection:0] atScrollPosition:scrollPosition animated:NO];
    }
    
    self.contentOffsetX = self.mainView.contentOffset.x;
    
    CGSize size = CGSizeZero;
    if ([self.pageControl isKindOfClass:[YWTAPageControl class]]) {
        YWTAPageControl *pageControl = (YWTAPageControl *)_pageControl;
        if (!(self.pageDotImage && self.currentPageDotImage && CGSizeEqualToSize(kCycleScrollViewInitialPageControlDotSize, self.pageControlDotSize))) {
            pageControl.dotSize = self.pageControlDotSize;
        }
        size = [pageControl sizeForNumberOfPages:self.imagePathsGroup.count];
    } else {
        size = CGSizeMake(self.imagePathsGroup.count * self.pageControlDotSize.width * 1.5, self.pageControlDotSize.height);
    }
    CGFloat x = (self.sd_width - size.width) * 0.5;
    if (self.pageControlAliment == YWSDCycleScrollViewPageContolAlimentRight) {
        x = self.mainView.sd_width - size.width - 10;
    }
    CGFloat y = self.mainView.sd_height - size.height - 10;
    
    if ([self.pageControl isKindOfClass:[YWTAPageControl class]]) {
        YWTAPageControl *pageControl = (YWTAPageControl *)_pageControl;
        [pageControl sizeToFit];
    }
    
    CGRect pageControlFrame = CGRectMake(x, y, size.width, size.height);
    pageControlFrame.origin.y -= self.pageControlBottomOffset;
    pageControlFrame.origin.x -= self.pageControlRightOffset;
    self.pageControl.frame = pageControlFrame;
    self.pageControl.hidden = !_showPageControl;
    
    if (self.backgroundImageView) {
        self.backgroundImageView.frame = self.bounds;
    }
    
}

//解决当父View释放时，当前视图因为被Timer强引用而不能释放的问题
- (void)willMoveToSuperview:(UIView *)newSuperview
{
    if (!newSuperview) {
        [self invalidateTimer];
    }
}

//解决当timer释放后 回调scrollViewDidScroll时访问野指针导致崩溃
- (void)dealloc {
    _mainView.delegate = nil;
    _mainView.dataSource = nil;
}

#pragma mark - public actions

- (void)adjustWhenControllerViewWillAppera
{
    long targetIndex = [self currentIndex];
    if (targetIndex < _totalItemsCount) {
        UICollectionViewScrollPosition scrollPosition;
        if (self.scrollDirection == UICollectionViewScrollDirectionHorizontal) {
            scrollPosition = UICollectionViewScrollPositionCenteredHorizontally;
        } else {
            scrollPosition = UICollectionViewScrollPositionCenteredVertically;
        }
        
        [_mainView scrollToItemAtIndexPath:[NSIndexPath indexPathForItem:targetIndex inSection:0] atScrollPosition:scrollPosition animated:YES];
    }
}


#pragma mark - UICollectionViewDataSource

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return _totalItemsCount;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    YWSDCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:ID forIndexPath:indexPath];
    
    long itemIndex = [self pageControlIndexWithCurrentCellIndex:indexPath.item];
    
    if ([self.delegate respondsToSelector:@selector(setupCustomCell:forIndex:cycleScrollView:)] &&
        [self.delegate respondsToSelector:@selector(customCollectionViewCellClassForCycleScrollView:)] && [self.delegate customCollectionViewCellClassForCycleScrollView:self]) {
        [self.delegate setupCustomCell:cell forIndex:itemIndex cycleScrollView:self];
        return cell;
    }else if ([self.delegate respondsToSelector:@selector(setupCustomCell:forIndex:cycleScrollView:)] &&
              [self.delegate respondsToSelector:@selector(customCollectionViewCellNibForCycleScrollView:)] && [self.delegate customCollectionViewCellNibForCycleScrollView:self]) {
        [self.delegate setupCustomCell:cell forIndex:itemIndex cycleScrollView:self];
        return cell;
    }
    
    NSString *imagePath = self.imagePathsGroup[itemIndex];
    
    if (!self.onlyDisplayText && [imagePath isKindOfClass:[NSString class]]) {
        if ([imagePath hasPrefix:@"http"]) {
            [cell.imageView sd_setImageWithURL:[NSURL URLWithString:imagePath] placeholderImage:self.placeholderImage];
        } else {
            UIImage *image = [UIImage imageNamed:imagePath];
            if (!image) {
                [UIImage imageWithContentsOfFile:imagePath];
            }
            cell.imageView.image = image;
        }
    } else if (!self.onlyDisplayText && [imagePath isKindOfClass:[UIImage class]]) {
        cell.imageView.image = (UIImage *)imagePath;
    }
    
    if (_titlesGroup.count && itemIndex < _titlesGroup.count) {
        cell.title = _titlesGroup[itemIndex];
    }
    
    if (!cell.hasConfigured) {
        cell.titleLabelBackgroundColor = self.titleLabelBackgroundColor;
        cell.titleLabelHeight = self.titleLabelHeight;
        cell.titleLabelTextColor = self.titleLabelTextColor;
        cell.titleLabelTextFont = self.titleLabelTextFont;
        cell.hasConfigured = YES;
        cell.imageView.contentMode = self.bannerImageViewContentMode;
        cell.clipsToBounds = YES;
        cell.onlyDisplayText = self.onlyDisplayText;
        cell.zoomType = self.zoomType;
    }
    
    if (self.zoomType) {
        if ([self currentIndex] == indexPath.item) {
            cell.imageView.frame = CGRectMake(0, 0, YWMaxWidth, _maxHeight);
        } else {
            cell.imageView.frame = CGRectMake(0, 0, YWMinWidth, _minHeight);
        }
        
        cell.imageView.center = cell.contentView.center;
    }
    
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    if ([self.delegate respondsToSelector:@selector(cycleScrollView:didSelectItemAtIndex:)]) {
        [self.delegate cycleScrollView:self didSelectItemAtIndex:[self pageControlIndexWithCurrentCellIndex:indexPath.item]];
    }
    if (self.clickItemOperationBlock) {
        self.clickItemOperationBlock([self pageControlIndexWithCurrentCellIndex:indexPath.item]);
    }
}


#pragma mark - UIScrollViewDelegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    if (!self.imagePathsGroup.count) return; // 解决清除timer时偶尔会出现的问题
    int itemIndex = [self currentIndex];
    int indexOnPageControl = [self pageControlIndexWithCurrentCellIndex:itemIndex];
    
    if ([self.pageControl isKindOfClass:[YWTAPageControl class]]) {
        YWTAPageControl *pageControl = (YWTAPageControl *)_pageControl;
        pageControl.currentPage = indexOnPageControl;
    } else {
        UIPageControl *pageControl = (UIPageControl *)_pageControl;
        pageControl.currentPage = indexOnPageControl;
    }
    
    // 图片缩放
    if (self.zoomType) {
        YWSDCollectionViewCell *lastCell = (YWSDCollectionViewCell *)[self.mainView cellForItemAtIndexPath:[NSIndexPath indexPathForItem:itemIndex - 1 inSection:0]];
        YWSDCollectionViewCell *currentCell = (YWSDCollectionViewCell *)[self.mainView cellForItemAtIndexPath:[NSIndexPath indexPathForItem:itemIndex inSection:0]];
        YWSDCollectionViewCell *nextCell = (YWSDCollectionViewCell *)[self.mainView cellForItemAtIndexPath:[NSIndexPath indexPathForItem:itemIndex + 1 inSection:0]];
        
        // 当前cell的偏移比例
        CGFloat scale = (fabs(self.flowLayout.itemSize.width * itemIndex - (self.mainView.contentOffset.x + (YWScreen_Width - self.flowLayout.itemSize.width)/2)))/self.flowLayout.itemSize.width;
        
        currentCell.imageView.frame = CGRectMake(0, 0, YWMaxWidth - scale * (YWMaxWidth - YWMinWidth), _maxHeight - scale * (_maxHeight - _minHeight));

        if (self.mainView.contentOffset.x > self.contentOffsetX) {
            // 向左滚动
            if (self.flowLayout.itemSize.width * itemIndex < self.mainView.contentOffset.x + (YWScreen_Width - self.flowLayout.itemSize.width)/2) {
                // 当前页图片缩小，下一页图片放大
                nextCell.imageView.frame = CGRectMake(0, 0, YWMinWidth + scale * (YWMaxWidth - YWMinWidth), _minHeight + scale * (_maxHeight - _minHeight));
            } else {
                // 当前页图片放大，前一页图片缩小
                lastCell.imageView.frame = CGRectMake(0, 0, YWMaxWidth - (1 - scale) * (YWMaxWidth - YWMinWidth), _maxHeight - (1 - scale) * (_maxHeight - _minHeight));
            }
        } else {
            // 向右滚动
            if (self.flowLayout.itemSize.width * itemIndex < self.mainView.contentOffset.x + (YWScreen_Width - self.flowLayout.itemSize.width)/2) {
                // 当前页图片放大，下一页图片缩小
                nextCell.imageView.frame = CGRectMake(0, 0, YWMinWidth + scale * (YWMaxWidth - YWMinWidth), _minHeight + scale * (_maxHeight - _minHeight));
            } else {
                // 当前页图片缩小，前一页图片放大
                lastCell.imageView.frame = CGRectMake(0, 0, YWMaxWidth - (1 - scale) * (YWMaxWidth - YWMinWidth), _maxHeight - (1 - scale) * (_maxHeight - _minHeight));
            }
        }
        
        currentCell.imageView.center = currentCell.contentView.center;
        nextCell.imageView.center = nextCell.contentView.center;
        lastCell.imageView.center = lastCell.contentView.center;
        
        self.contentOffsetX = self.mainView.contentOffset.x;
    }
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
    if (self.autoScroll) {
        [self invalidateTimer];
    }
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{
    if (self.zoomType) {
        dispatch_async(dispatch_get_main_queue(), ^{
            int index = [self currentIndex];
            [self scrollToIndex:index];
        });
    }
    
    if (self.autoScroll) {
        [self setupTimer];
    }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    [self scrollViewDidEndScrollingAnimation:self.mainView];
}

- (void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView
{
    self.contentOffsetX = self.mainView.contentOffset.x;
    
    if (!self.imagePathsGroup.count) return; // 解决清除timer时偶尔会出现的问题
    int itemIndex = [self currentIndex];
    int indexOnPageControl = [self pageControlIndexWithCurrentCellIndex:itemIndex];
    
    if ([self.delegate respondsToSelector:@selector(cycleScrollView:didScrollToIndex:)]) {
        [self.delegate cycleScrollView:self didScrollToIndex:indexOnPageControl];
    } else if (self.itemDidScrollOperationBlock) {
        self.itemDidScrollOperationBlock(indexOnPageControl);
    }
}


@end
