import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';

// ==================== ARTICLE DETAIL PAGE ====================
class ArticleDetailPage extends StatelessWidget {
  final Map<String, dynamic> article;
  const ArticleDetailPage({Key? key, required this.article}) : super(key: key);

  static const Color PRIMARY_GREEN = Color(0xFF10B981);
  static const Color PRIMARY_PINK = Color(0xFFEC4899);

  String _getDomainFromUrl(String? url) {
    if (url == null || url.isEmpty) return 'News Source';
    try {
      final uri = Uri.parse(url);
      var host = uri.host;
      if (host.isEmpty) return 'News Source';
      if (host.startsWith('www.')) host = host.substring(4);
      return host.isNotEmpty ? host : 'News Source';
    } catch (e) {
      return 'News Source';
    }
  }

  bool _hasAiRewritingTag() {
    final content = article['content'] ?? '';
    final aiPatterns = [
      '[This article was rewritten using A.I]',
      '[This article was rewritten using A.I.]',
      '(This article was rewritten using A.I.)',
      'This article was rewritten using A.I.',
      '[Rewritten by AI]',
      '(Rewritten by AI)',
      'Rewritten by AI:',
      'AI Rewritten:',
      '[This article was rewritten using AI.]',
      '(This article was rewritten using AI.)',
      'This article was rewritten using AI.',
    ];
    return aiPatterns.any((pattern) => content.contains(pattern));
  }

  String _removeAiText(String content) {
    final aiPatterns = [
      '[This article was rewritten using A.I]',
      '[This article was rewritten using A.I.]',
      '(This article was rewritten using A.I.)',
      'This article was rewritten using A.I.',
      '[Rewritten by AI]',
      '(Rewritten by AI)',
      'Rewritten by AI:',
      'AI Rewritten:',
      '[This article was rewritten using AI.]',
      '(This article was rewritten using AI.)',
      'This article was rewritten using AI.',
    ];
    var result = content;
    for (var pattern in aiPatterns) {
      result = result.replaceAll(pattern, '');
    }
    return result.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  String _formatRelativeTime(dynamic dateStr) {
    if (dateStr == null) return 'Recent';
    try {
      DateTime date = dateStr is String
          ? (dateStr.contains('GMT') ? _parseGMTDate(dateStr) : DateTime.parse(dateStr))
          : dateStr is DateTime ? dateStr : DateTime.now();
      final now = DateTime.now();
      final diff = now.difference(date);
      if (diff.inSeconds < 60) return 'Just now';
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      if (diff.inDays < 7) return '${diff.inDays}d ago';
      if (diff.inDays < 30) return '${(diff.inDays / 7).floor()}w ago';
      if (diff.inDays < 365) return '${(diff.inDays / 30).floor()}mo ago';
      return '${(diff.inDays / 365).floor()}y ago';
    } catch (e) {
      return 'Recent';
    }
  }

  DateTime _parseGMTDate(String dateStr) {
    final parts = dateStr.split(' ');
    if (parts.length < 5) throw FormatException('Invalid GMT format');
    final day = int.parse(parts[1]);
    final month = _monthToNumber(parts[2]);
    final year = int.parse(parts[3]);
    final timeParts = parts[4].split(':');
    final hour = int.parse(timeParts[0]);
    final minute = int.parse(timeParts[1]);
    final second = int.parse(timeParts[2]);
    return DateTime.utc(year, month, day, hour, minute, second);
  }

  int _monthToNumber(String month) {
    const months = {
      'Jan': 1, 'Feb': 2, 'Mar': 3, 'Apr': 4, 'May': 5, 'Jun': 6,
      'Jul': 7, 'Aug': 8, 'Sep': 9, 'Oct': 10, 'Nov': 11, 'Dec': 12,
    };
    return months[month] ?? 1;
  }

  Future<void> _openInAppBrowser() async {
    final url = article['source_url'] ?? '';
    if (url.isNotEmpty) {
      try {
        await launchUrl(Uri.parse(url), mode: LaunchMode.inAppWebView);
      } catch (e) {
        debugPrint('⚠️ Error opening URL: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final imageUrl = article['image_url'] as String?;
    final title = article['title'] ?? 'No Title';
    final content = _removeAiText(article['content'] ?? 'No content available');
    final sourceDomain = _getDomainFromUrl(article['source_url']);
    final timeText = _formatRelativeTime(article['created_at']);
    final category = article['category'] ?? 'News';
    final isAiRewritten = article['is_ai_rewritten'] == 1 ||
        article['is_ai_rewritten'] == true ||
        article['is_ai_rewritten'] == '1';
    final hasAiTag = _hasAiRewritingTag();
    final showAiTag = isAiRewritten && hasAiTag;

    return Scaffold(
      backgroundColor: isDark ? Colors.grey[900] : Colors.white,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              floating: true,
              snap: true,
              backgroundColor: isDark ? Colors.grey[900] : Colors.white,
              elevation: 0,
              leading: Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: colorScheme.primary.withOpacity(0.1),
                ),
                child: IconButton(
                  icon: Icon(Icons.arrow_back_ios_rounded,
                      color: colorScheme.primary, size: 20),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
              actions: [
                Container(
                  margin: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: colorScheme.primary.withOpacity(0.1),
                  ),
                  child: IconButton(
                    icon: Icon(Icons.share_rounded,
                        color: colorScheme.primary, size: 20),
                    onPressed: () {},
                  ),
                ),
              ],
            ),
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (imageUrl != null && imageUrl.isNotEmpty)
                    SizedBox(
                      height: screenHeight * 0.3,
                      width: screenWidth,
                      child: Hero(
                        tag: 'article_${article['id']}',
                        child: CachedNetworkImage(
                          imageUrl: imageUrl,
                          fit: BoxFit.cover,
                          fadeInDuration: const Duration(milliseconds: 150),
                          placeholder: (context, url) => Container(
                            color: isDark ? Colors.grey[850] : Colors.grey[100],
                            child: Center(
                                child: CircularProgressIndicator(
                                    color: PRIMARY_GREEN)),
                          ),
                          errorWidget: (context, url, error) => Container(
                            color: isDark ? Colors.grey[850] : Colors.grey[100],
                            child: Center(
                              child: Icon(Icons.image_not_supported_rounded,
                                  color: isDark
                                      ? Colors.grey[600]
                                      : Colors.grey[400],
                                  size: 50),
                            ),
                          ),
                        ),
                      ),
                    )
                  else
                    Container(
                      height: screenHeight * 0.25,
                      width: screenWidth,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [PRIMARY_GREEN, PRIMARY_PINK],
                        ),
                      ),
                      child: const Center(
                        child: Icon(Icons.newspaper,
                            color: Colors.white, size: 60),
                      ),
                    ),
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      screenWidth > 600 ? 32 : 16,
                      24,
                      screenWidth > 600 ? 32 : 16,
                      24,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      colorScheme.primary.withOpacity(0.15),
                                      colorScheme.primary.withOpacity(0.08),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: colorScheme.primary.withOpacity(0.3),
                                    width: 1,
                                  ),
                                ),
                                child: Text(
                                  category,
                                  style: GoogleFonts.poppins(
                                    color: colorScheme.primary,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12,
                                    letterSpacing: 0.3,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                            const Spacer(),
                            Icon(Icons.access_time_rounded,
                                size: 14,
                                color: isDark
                                    ? Colors.white70
                                    : Colors.grey[600]),
                            const SizedBox(width: 4),
                            Text(
                              timeText,
                              style: GoogleFonts.inter(
                                color: isDark
                                    ? Colors.white70
                                    : Colors.grey[600],
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          title,
                          style: GoogleFonts.poppins(
                            fontSize: screenWidth > 600 ? 28 : 24,
                            fontWeight: FontWeight.bold,
                            height: 1.3,
                            color: isDark ? Colors.white : Colors.grey[900],
                            letterSpacing: 0.2,
                          ),
                        ),
                        const SizedBox(height: 16),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: colorScheme.primary.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: colorScheme.primary.withOpacity(0.2),
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.language_rounded,
                                        size: 12, color: colorScheme.primary),
                                    const SizedBox(width: 4),
                                    Text(
                                      sourceDomain,
                                      style: GoogleFonts.inter(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: colorScheme.primary,
                                        letterSpacing: 0.2,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (showAiTag)
                                Padding(
                                  padding: const EdgeInsets.only(left: 8),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 5),
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: [PRIMARY_GREEN, PRIMARY_PINK],
                                      ),
                                      borderRadius: BorderRadius.circular(10),
                                      boxShadow: [
                                        BoxShadow(
                                          color: PRIMARY_GREEN.withOpacity(0.4),
                                          blurRadius: 6,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.auto_awesome,
                                            color: Colors.white, size: 12),
                                        const SizedBox(width: 4),
                                        Text(
                                          'AI Enhanced',
                                          style: GoogleFonts.poppins(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 10,
                                            letterSpacing: 0.3,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.grey[850]?.withOpacity(0.6)
                                : Colors.grey[50],
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isDark
                                  ? Colors.grey[700]!.withOpacity(0.3)
                                  : Colors.grey[200]!,
                              width: 1,
                            ),
                          ),
                          child: Text(
                            content,
                            style: GoogleFonts.inter(
                              fontSize: screenWidth > 600 ? 16 : 15,
                              height: 1.8,
                              color: isDark
                                  ? Colors.white.withOpacity(0.87)
                                  : Colors.grey[700],
                              letterSpacing: 0.3,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: _openInAppBrowser,
                            borderRadius: BorderRadius.circular(18),
                            child: Ink(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                  colors: [
                                    colorScheme.primary,
                                    colorScheme.primary.withOpacity(0.8),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(18),
                                boxShadow: [
                                  BoxShadow(
                                    color: colorScheme.primary.withOpacity(0.4),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                    spreadRadius: 0,
                                  ),
                                ],
                              ),
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 24, vertical: 15),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.auto_stories_rounded,
                                        color: Colors.white, size: 22),
                                    const SizedBox(width: 10),
                                    Flexible(
                                      child: Text(
                                        'Read Full Article',
                                        style: GoogleFonts.poppins(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white,
                                          letterSpacing: 0.5,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    const Icon(Icons.arrow_forward_rounded,
                                        color: Colors.white, size: 20),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==================== INSHOT STYLE - IMAGE OVERLAY CARD ====================
class ArticleCardWidget extends StatelessWidget {
  final Map<String, dynamic> article;
  final Function(Map<String, dynamic>) onTrackRead;
  final Function(Map<String, dynamic>) onShare;

  const ArticleCardWidget({
    Key? key,
    required this.article,
    required this.onTrackRead,
    required this.onShare,
  }) : super(key: key);

  static const Color PRIMARY_GREEN = Color(0xFF10B981);
  static const Color PRIMARY_PINK = Color(0xFFEC4899);

  String _getShortTitle(String fullTitle) {
    final words = fullTitle.trim().split(' ');
    if (words.length <= 5) return fullTitle;
    return words.take(5).join(' ') + '...';
  }

  Widget _buildDefaultArticleImage() {
    final title = article['title'] ?? 'No Title';
    final shortTitle = _getShortTitle(title);
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [PRIMARY_GREEN, PRIMARY_PINK],
        ),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            shortTitle,
            textAlign: TextAlign.center,
            style: GoogleFonts.cinzel(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              height: 1.3,
              shadows: const [
                Shadow(
                  color: Colors.black45,
                  offset: Offset(0, 2),
                  blurRadius: 6,
                ),
              ],
            ),
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }

  String _removeAiText(String content) {
    final aiPatterns = [
      '[This article was rewritten using A.I]',
      '[This article was rewritten using A.I.]',
      '(This article was rewritten using A.I.)',
      '[Rewritten by AI]',
      'AI Rewritten:',
    ];
    var result = content;
    for (var pattern in aiPatterns) {
      result = result.replaceAll(pattern, '');
    }
    return result.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  int _getSummaryCharLimit(double screenWidth) {
    if (screenWidth >= 800) return 900;
    if (screenWidth >= 700) return 750;
    if (screenWidth >= 600) return 650;
    return 450;
  }

  String _getSummaryText(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final charLimit = _getSummaryCharLimit(screenWidth);
    final cleanContent = _removeAiText(article['content'] ?? 'No content available');
    if (cleanContent.length <= charLimit) return cleanContent;
    final truncated = cleanContent.substring(0, charLimit);
    final lastSpace = truncated.lastIndexOf(' ');
    if (lastSpace == -1) return truncated + '...';
    return truncated.substring(0, lastSpace) + '...';
  }

  int _getSummaryMaxLines(double screenWidth) {
    if (screenWidth >= 600) return 15;
    if (screenWidth >= 400) return 15;
    return 6;
  }

  bool _hasAiRewritingTag() {
    final content = article['content'] ?? '';
    final aiPatterns = [
      '[This article was rewritten using A.I]',
      '[This article was rewritten using A.I.]',
      '(This article was rewritten using A.I.)',
      '[Rewritten by AI]',
      'AI Rewritten:',
    ];
    return aiPatterns.any((pattern) => content.contains(pattern));
  }

  String _getDomainFromUrl(String? url) {
    if (url == null || url.isEmpty) return 'News';
    try {
      final uri = Uri.parse(url);
      var host = uri.host;
      if (host.startsWith('www.')) host = host.substring(4);
      return host.isNotEmpty ? host : 'News';
    } catch (e) {
      return 'News';
    }
  }

  String _formatRelativeTime(dynamic dateStr) {
    if (dateStr == null) return 'Recent';
    try {
      DateTime date = dateStr is String
          ? (dateStr.contains('GMT') ? _parseGMTDate(dateStr) : DateTime.parse(dateStr))
          : dateStr is DateTime ? dateStr : DateTime.now();
      final now = DateTime.now();
      final diff = now.difference(date);
      if (diff.inSeconds < 60) return 'Just now';
      if (diff.inMinutes < 60) return '${diff.inMinutes}m';
      if (diff.inHours < 24) return '${diff.inHours}h';
      if (diff.inDays < 7) return '${diff.inDays}d';
      return '${(diff.inDays / 7).floor()}w';
    } catch (e) {
      return 'Recent';
    }
  }

  DateTime _parseGMTDate(String dateStr) {
    final parts = dateStr.split(' ');
    if (parts.length < 5) throw FormatException('Invalid GMT format');
    final day = int.parse(parts[1]);
    final month = _monthToNumber(parts[2]);
    final year = int.parse(parts[3]);
    final timeParts = parts[4].split(':');
    return DateTime.utc(year, month, day, int.parse(timeParts[0]), int.parse(timeParts[1]), int.parse(timeParts[2]));
  }

  int _monthToNumber(String month) {
    const months = {'Jan': 1, 'Feb': 2, 'Mar': 3, 'Apr': 4, 'May': 5, 'Jun': 6, 'Jul': 7, 'Aug': 8, 'Sep': 9, 'Oct': 10, 'Nov': 11, 'Dec': 12};
    return months[month] ?? 1;
  }

  Future<void> _openInAppBrowser(BuildContext context) async {
    final url = article['source_url'] ?? '';
    if (url.isNotEmpty) {
      try {
        await launchUrl(Uri.parse(url), mode: LaunchMode.inAppWebView);
      } catch (e) {
        debugPrint('⚠️ Error opening URL: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    final isAiRewritten = article['is_ai_rewritten'] == 1 || article['is_ai_rewritten'] == true || article['is_ai_rewritten'] == '1';
    final hasAiTag = _hasAiRewritingTag();
    final showAiTag = isAiRewritten && hasAiTag;

    final sourceDomain = _getDomainFromUrl(article['source_url']);
    final timeText = _formatRelativeTime(article['created_at']);
    final title = article['title'] ?? 'No Title';
    final summary = _getSummaryText(context);
    final summaryMaxLines = _getSummaryMaxLines(screenWidth);

    final imageHeight = screenWidth > 600 ? 280.0 : screenWidth > 400 ? 260.0 : 240.0;
    final contentPadding = screenWidth > 600 ? 20.0 : screenWidth > 400 ? 18.0 : 16.0;

    Widget buildImageWidget() {
      final imageUrl = article['image_url'] as String?;
      if (imageUrl != null && imageUrl.isNotEmpty) {
        return CachedNetworkImage(
          imageUrl: imageUrl,
          fit: BoxFit.cover,
          memCacheWidth: 800,
          memCacheHeight: 600,
          fadeInDuration: const Duration(milliseconds: 200),
          placeholder: (context, url) => Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [PRIMARY_GREEN.withOpacity(0.3), PRIMARY_PINK.withOpacity(0.3)],
              ),
            ),
            child: const Center(child: CircularProgressIndicator(color: PRIMARY_GREEN, strokeWidth: 2.5)),
          ),
          errorWidget: (context, url, error) => _buildDefaultArticleImage(),
        );
      } else {
        return _buildDefaultArticleImage();
      }
    }

    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: screenWidth > 600 ? 20.0 : screenWidth > 400 ? 16.0 : 14.0,
        vertical: screenHeight > 800 ? 12.0 : 10.0,
      ),
      constraints: screenWidth > 600 ? const BoxConstraints(maxWidth: 450) : null,
      child: Card(
        elevation: 8,
        margin: EdgeInsets.zero,
        shadowColor: isDark ? PRIMARY_GREEN.withOpacity(0.4) : Colors.black.withOpacity(0.2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        color: isDark ? const Color(0xFF121212) : Colors.white,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            children: [
              SizedBox(
                height: imageHeight,
                width: double.infinity,
                child: Hero(
                  tag: 'article_${article['id']}',
                  child: buildImageWidget(),
                ),
              ),

              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Container(
                  height: 80,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        isDark ? Colors.black.withOpacity(0.7) : Colors.black.withOpacity(0.5),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),

              Positioned(
                top: 16,
                right: 16,
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        isDark ? Colors.white.withOpacity(0.95) : Colors.white.withOpacity(0.95),
                        isDark ? Colors.white.withOpacity(0.88) : Colors.white.withOpacity(0.88),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: isDark ? Colors.black.withOpacity(0.5) : Colors.black.withOpacity(0.35),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => onShare(article),
                      borderRadius: BorderRadius.circular(50),
                      splashColor: Colors.grey.withOpacity(0.3),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        child: Icon(Icons.share_rounded, color: colorScheme.primary, size: 24),
                      ),
                    ),
                  ),
                ),
              ),

              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                top: imageHeight,
                child: Padding(
                  padding: EdgeInsets.only(
                    left: contentPadding,
                    right: contentPadding,
                    top: 12,
                    bottom: contentPadding,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? PRIMARY_GREEN.withOpacity(0.3)
                                  : PRIMARY_GREEN.withOpacity(0.28),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isDark
                                    ? PRIMARY_GREEN.withOpacity(0.5)
                                    : PRIMARY_GREEN.withOpacity(0.5),
                                width: 1,
                              ),
                            ),
                            child: Text(
                              article['category'] ?? 'News',
                              style: GoogleFonts.poppins(
                                color: isDark ? Colors.white : Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: screenWidth > 600 ? 11 : 10.5,
                                letterSpacing: 0.4,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Icon(Icons.access_time_rounded, size: 12, color: isDark ? Colors.white60 : Colors.black45),
                          const SizedBox(width: 4),
                          Text(
                            timeText,
                            style: GoogleFonts.inter(
                              color: isDark ? Colors.white60 : Colors.black45,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: screenWidth > 600 ? 8 : 6),

                      Text(
                        title,
                        style: GoogleFonts.merriweather(
                          fontSize: screenWidth > 600 ? 18.5 : screenWidth > 400 ? 17.5 : 16.5,
                          fontWeight: FontWeight.w900,
                          height: 1.15,
                          color: isDark ? Colors.white : Colors.black,
                          letterSpacing: -0.2,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: screenWidth > 600 ? 6 : 5),

                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? Colors.white.withOpacity(0.2)
                                  : Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isDark
                                    ? Colors.white.withOpacity(0.3)
                                    : Colors.white.withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.language_rounded, size: screenWidth > 600 ? 12 : 11, color: isDark ? Colors.white : Colors.black),
                                const SizedBox(width: 4),
                                Text(
                                  sourceDomain,
                                  style: GoogleFonts.inter(
                                    fontSize: screenWidth > 600 ? 11 : 10.5,
                                    fontWeight: FontWeight.w600,
                                    color: isDark ? Colors.white : Colors.black,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (showAiTag)
                            Padding(
                              padding: const EdgeInsets.only(left: 8),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    begin: Alignment.centerLeft,
                                    end: Alignment.centerRight,
                                    colors: [PRIMARY_GREEN, PRIMARY_PINK],
                                  ),
                                  borderRadius: BorderRadius.circular(10),
                                  boxShadow: [
                                    BoxShadow(
                                      color: PRIMARY_GREEN.withOpacity(0.6),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.auto_awesome, color: Colors.white, size: screenWidth > 600 ? 12 : 11),
                                    const SizedBox(width: 4),
                                    Text(
                                      'AI Enhanced',
                                      style: GoogleFonts.poppins(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w700,
                                        fontSize: screenWidth > 600 ? 9 : 8.5,
                                        letterSpacing: 0.3,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                      SizedBox(height: screenWidth > 600 ? 8 : 6),

                      Expanded(
                        child: SingleChildScrollView(
                          child: Text(
                            summary,
                            style: GoogleFonts.inter(
                              fontSize: screenWidth > 600 ? 14.5 : screenWidth > 400 ? 12.5 : 12,
                              height: 1.5,
                              color: isDark ? Colors.white70 : Colors.black87,
                              letterSpacing: 0.15,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: screenWidth > 600 ? 12 : 10),

                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            onTrackRead(article);
                            _openInAppBrowser(context);
                          },
                          borderRadius: BorderRadius.circular(16),
                          splashColor: isDark ? Colors.white.withOpacity(0.2) : Colors.black.withOpacity(0.1),
                          child: Ink(
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                                colors: [PRIMARY_GREEN, PRIMARY_PINK],
                              ),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: PRIMARY_GREEN.withOpacity(0.6),
                                  blurRadius: 15,
                                  offset: const Offset(0, 4),
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                            child: Container(
                              width: double.infinity,
                              padding: EdgeInsets.symmetric(
                                horizontal: screenWidth > 600 ? 20 : 18,
                                vertical: screenWidth > 600 ? 13 : 12,
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.auto_stories_rounded, color: Colors.white, size: screenWidth > 600 ? 20 : 19),
                                  const SizedBox(width: 10),
                                  Flexible(
                                    child: Text(
                                      'Read Full Article',
                                      style: GoogleFonts.poppins(
                                        fontSize: screenWidth > 600 ? 15 : 14,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                        letterSpacing: 0.6,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Icon(Icons.arrow_forward_rounded, color: Colors.white, size: screenWidth > 600 ? 20 : 19),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}