import 'package:flutter/material.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:provider/provider.dart';
import 'package:animate_do/animate_do.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../config/app_config.dart';
import '../providers/app_provider.dart';
import '../services/api_service.dart';

class SwipeScreen extends StatefulWidget {
  const SwipeScreen({super.key});

  @override
  State<SwipeScreen> createState() => _SwipeScreenState();
}

class _SwipeScreenState extends State<SwipeScreen> {
  final CardSwiperController _controller = CardSwiperController();
  final ApiService _api = ApiService();

  String _selectedType = 'hotels';
  List<Map<String, dynamic>> _recommendations = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadRecommendations();
  }

  Future<void> _loadRecommendations() async {
    setState(() => _loading = true);
    try {
      final data = await _api.getSwipeRecommendations(type: _selectedType);
      setState(() {
        _recommendations =
            List<Map<String, dynamic>>.from(data['recommendations'] ?? []);
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading recommendations: $e')),
        );
      }
    }
  }

  bool _handleSwipe(
      int previousIndex, int? currentIndex, CardSwiperDirection direction) {
    if (previousIndex >= _recommendations.length) return true;

    final item = _recommendations[previousIndex];
    final action = direction == CardSwiperDirection.right ? 'like' : 'dislike';

    // Update local state
    final provider = context.read<AppProvider>();
    provider.recordSwipe(action == 'like');

    // Send to backend asynchronously
    _api
        .handleSwipe(
      cardId: item['id']?.toString() ?? '',
      action: action,
      type: _selectedType,
      cardData: item,
    )
        .catchError((e) {
      print('Error tracking swipe: $e');
      return <String, dynamic>{};
    });

    // Show feedback
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(action == 'like'
              ? '❤️ Added to favorites!'
              : '👎 Not interested'),
          duration: const Duration(milliseconds: 800),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }

    return true;
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Discover & Swipe'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.insights),
            onPressed: () => _showInsights(provider),
          ),
        ],
      ),
      body: Column(
        children: [
          // Header content that might need scrolling on very small screens
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Column(
              children: [
                // Type Selector
                FadeInDown(
                  child: _TypeSelector(
                    selectedType: _selectedType,
                    onChanged: (type) {
                      setState(() => _selectedType = type);
                      _loadRecommendations();
                    },
                  ),
                ),

                const SizedBox(height: 16),

                // Stats Bar
                FadeInDown(
                  delay: const Duration(milliseconds: 100),
                  child: _StatsBar(
                    totalSwipes: provider.totalSwipes,
                    likesCount: provider.likesCount,
                    dislikesCount: provider.dislikesCount,
                    acceptanceRate: provider.acceptanceRate,
                  ),
                ),

                const SizedBox(height: 16),
              ],
            ),
          ),

          // Swipe Cards - must remain in constrained space
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _recommendations.isEmpty
                    ? _EmptyState(onRefresh: _loadRecommendations)
                    : FadeIn(
                        child: CardSwiper(
                          controller: _controller,
                          cardsCount: _recommendations.length,
                          onSwipe: _handleSwipe,
                          numberOfCardsDisplayed: 3,
                          backCardOffset: const Offset(0, 40),
                          padding: const EdgeInsets.all(24),
                          cardBuilder: (context, index, percentThresholdX,
                              percentThresholdY) {
                            return _SwipeCard(
                              item: _recommendations[index],
                              type: _selectedType,
                            );
                          },
                        ),
                      ),
          ),

          // Action Buttons
          FadeInUp(
            child: _ActionButtons(
              onDislike: () => _controller.swipe(CardSwiperDirection.left),
              onLike: () => _controller.swipe(CardSwiperDirection.right),
              onUndo: () => _controller.undo(),
            ),
          ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }

  void _showInsights(AppProvider provider) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Your Preference Insights',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            _InsightRow(
              icon: Icons.thumb_up,
              label: 'Total Likes',
              value: provider.likesCount.toString(),
              color: Colors.green,
            ),
            _InsightRow(
              icon: Icons.thumb_down,
              label: 'Total Dislikes',
              value: provider.dislikesCount.toString(),
              color: Colors.red,
            ),
            _InsightRow(
              icon: Icons.trending_up,
              label: 'Acceptance Rate',
              value: '${provider.acceptanceRate.toStringAsFixed(1)}%',
              color: AppConfig.primaryColor,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppConfig.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const FaIcon(FontAwesomeIcons.brain,
                      color: AppConfig.primaryColor),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      provider.totalSwipes < 5
                          ? 'Swipe ${5 - provider.totalSwipes} more items to get personalized recommendations!'
                          : 'Your recommendations are now personalized based on ${provider.totalSwipes} swipes!',
                      style: const TextStyle(fontSize: 12),
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

class _TypeSelector extends StatelessWidget {
  final String selectedType;
  final Function(String) onChanged;

  const _TypeSelector({
    required this.selectedType,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(12),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _TypeChip(
              icon: Icons.hotel,
              label: 'Hotels',
              isSelected: selectedType == 'hotels',
              onTap: () => onChanged('hotels'),
            ),
            _TypeChip(
              icon: Icons.place,
              label: 'Destinations',
              isSelected: selectedType == 'destinations',
              onTap: () => onChanged('destinations'),
            ),
            _TypeChip(
              icon: Icons.flight,
              label: 'Travel',
              isSelected: selectedType == 'travel',
              onTap: () => onChanged('travel'),
            ),
            _TypeChip(
              icon: Icons.attractions,
              label: 'Attractions',
              isSelected: selectedType == 'attractions',
              onTap: () => onChanged('attractions'),
            ),
          ],
        ),
      ),
    );
  }
}

class _TypeChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _TypeChip({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? AppConfig.primaryColor : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                size: 20,
                color: isSelected ? Colors.white : Colors.grey[600],
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: isSelected ? Colors.white : Colors.grey[600],
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatsBar extends StatelessWidget {
  final int totalSwipes;
  final int likesCount;
  final int dislikesCount;
  final double acceptanceRate;

  const _StatsBar({
    required this.totalSwipes,
    required this.likesCount,
    required this.dislikesCount,
    required this.acceptanceRate,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: AppConfig.primaryGradient,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _StatItem(
              icon: Icons.swipe, label: 'Total', value: totalSwipes.toString()),
          _StatItem(
              icon: Icons.favorite,
              label: 'Likes',
              value: likesCount.toString()),
          _StatItem(
              icon: Icons.close,
              label: 'Dislikes',
              value: dislikesCount.toString()),
          _StatItem(
              icon: Icons.percent,
              label: 'Rate',
              value: '${acceptanceRate.toStringAsFixed(0)}%'),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _StatItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.8),
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}

class _SwipeCard extends StatelessWidget {
  final Map<String, dynamic> item;
  final String type;

  const _SwipeCard({required this.item, required this.type});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            // Background Image
            Container(
              decoration: const BoxDecoration(
                gradient: AppConfig.primaryGradient,
              ),
              child: const Center(
                child: Icon(Icons.image, size: 100, color: Colors.white54),
              ),
            ),

            // Content Overlay
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.8),
                    ],
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item['name'] ?? 'Unknown',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (item['city'] != null)
                      Row(
                        children: [
                          const Icon(Icons.location_on,
                              color: Colors.white70, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            item['city'],
                            style: const TextStyle(color: Colors.white70),
                          ),
                        ],
                      ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        if (item['rating'] != null) ...[
                          const Icon(Icons.star, color: Colors.amber, size: 18),
                          const SizedBox(width: 4),
                          Text(
                            item['rating'].toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 16),
                        ],
                        if (item['price'] != null) ...[
                          const Icon(Icons.currency_rupee,
                              color: Colors.greenAccent, size: 16),
                          Text(
                            item['price'].toString(),
                            style: const TextStyle(
                              color: Colors.greenAccent,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (item['description'] != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        item['description'],
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 12),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionButtons extends StatelessWidget {
  final VoidCallback onDislike;
  final VoidCallback onLike;
  final VoidCallback onUndo;

  const _ActionButtons({
    required this.onDislike,
    required this.onLike,
    required this.onUndo,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _ActionButton(
            icon: Icons.close,
            color: AppConfig.errorColor,
            onPressed: onDislike,
          ),
          _ActionButton(
            icon: Icons.undo,
            color: Colors.grey,
            onPressed: onUndo,
            size: 50,
          ),
          _ActionButton(
            icon: Icons.favorite,
            color: AppConfig.successColor,
            onPressed: onLike,
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onPressed;
  final double size;

  const _ActionButton({
    required this.icon,
    required this.color,
    required this.onPressed,
    this.size = 65,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: IconButton(
        icon: Icon(icon, color: color, size: size * 0.45),
        onPressed: onPressed,
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onRefresh;

  const _EmptyState({required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.inbox, size: 80, color: Colors.grey),
          const SizedBox(height: 16),
          const Text(
            'No more recommendations',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          const Text(
            'Check back later for more!',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: onRefresh,
            icon: const Icon(Icons.refresh),
            label: const Text('Refresh'),
          ),
        ],
      ),
    );
  }
}

class _InsightRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _InsightRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 16),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
