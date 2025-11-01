import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:auto_route/auto_route.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import '../../../../generated/l10n.dart';

@RoutePage()
class PaywallScreen extends StatefulWidget {
  const PaywallScreen({super.key});

  @override
  State<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends State<PaywallScreen> with TickerProviderStateMixin {
  late AnimationController _storageAnimationController;
  late Animation<double> _storageAnimation;
  bool _isTrialEnabled = true;
  bool _isLoading = false;

  final InAppPurchase _inAppPurchase = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _subscription;
  List<ProductDetails> _products = [];

  @override
  void initState() {
    super.initState();

    // Storage animation
    _storageAnimationController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );

    _storageAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _storageAnimationController, curve: Curves.easeInOut));

    _storageAnimationController.repeat();

    // Initialize in-app purchases
    _initializeInAppPurchase();
  }

  Future<void> _initializeInAppPurchase() async {
    final bool available = await _inAppPurchase.isAvailable();
    if (!available) {
      return;
    }

    // Listen to purchase updates
    _subscription = _inAppPurchase.purchaseStream.listen(
      _onPurchaseUpdate,
      onDone: _updateStreamOnDone,
      onError: _updateStreamOnError,
    );

    // Load products
    const Set<String> productIds = {
      'ai_cleaner_premium_trial', // Replace with your actual product ID
    };

    final ProductDetailsResponse response = await _inAppPurchase.queryProductDetails(productIds);

    if (response.error != null) {
      debugPrint('Error loading products: ${response.error}');
      return;
    }

    if (response.productDetails.isEmpty) {
      debugPrint('No products found');
      return;
    }

    setState(() {
      _products = response.productDetails;
    });
  }

  void _onPurchaseUpdate(List<PurchaseDetails> purchases) async {
    for (final purchase in purchases) {
      if (purchase.status == PurchaseStatus.pending) {
        setState(() => _isLoading = true);
      } else if (purchase.status == PurchaseStatus.error) {
        setState(() => _isLoading = false);
        _showErrorDialog(purchase.error?.message ?? 'Purchase failed');
      } else if (purchase.status == PurchaseStatus.purchased ||
          purchase.status == PurchaseStatus.restored) {
        // Verify purchase with your backend here
        setState(() => _isLoading = false);
        _showSuccessDialog();
      }

      if (purchase.pendingCompletePurchase) {
        await _inAppPurchase.completePurchase(purchase);
      }
    }
  }

  void _updateStreamOnDone() {
    _subscription?.cancel();
  }

  void _updateStreamOnError(dynamic error) {
    debugPrint('Purchase stream error: $error');
  }

  Future<void> _startTrial() async {
    if (_products.isEmpty) {
      _showErrorDialog('Products not loaded yet. Please try again.');
      return;
    }

    setState(() => _isLoading = true);

    final ProductDetails product = _products.first;
    final PurchaseParam purchaseParam = PurchaseParam(productDetails: product);

    try {
      await _inAppPurchase.buyNonConsumable(purchaseParam: purchaseParam);
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorDialog(e.toString());
    }
  }

  Future<void> _restorePurchases() async {
    setState(() => _isLoading = true);
    try {
      await _inAppPurchase.restorePurchases();
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorDialog(e.toString());
    }
  }

  void _showErrorDialog(String message) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text(Locales.current.error),
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            child: const Text('OK'),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  void _showSuccessDialog() {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text(Locales.current.success),
        content: Text(Locales.current.trial_activated),
        actions: [
          CupertinoDialogAction(
            child: const Text('OK'),
            onPressed: () {
              Navigator.of(context).pop();
              context.router.maybePop();
            },
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _storageAnimationController.dispose();
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final trialDate = DateTime.now().add(const Duration(days: 3));

    return Material(
      child: CupertinoPageScaffold(
        backgroundColor: const Color(0xFF0A0E27),
        child: Stack(
          children: [
            // Animated background gradient
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [const Color(0xFF0A0E27), const Color(0xFF1a1f3a).withOpacity(0.8)],
                  ),
                ),
              ),
            ),
      
            SafeArea(
              child: Column(
                children: [
                  // Close button
                  Align(
                    alignment: Alignment.topRight,
                    child: CupertinoButton(
                      onPressed: () => context.router.maybePop(),
                      child: const Icon(
                        CupertinoIcons.xmark_circle_fill,
                        color: Colors.white54,
                        size: 30,
                      ),
                    ),
                  ),
      
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      children: [
                        const SizedBox(height: 30),
      
                        // Crown icon with animation
                        Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: const LinearGradient(
                                  colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFFFFD700).withOpacity(0.5),
                                    blurRadius: 30,
                                    spreadRadius: 5,
                                  ),
                                ],
                              ),
                              child: Icon(CupertinoIcons.chevron_down, size: 40, color: Colors.white),
                            )
                            .animate(onPlay: (controller) => controller.repeat())
                            .shimmer(duration: 2000.ms, color: Colors.white.withOpacity(0.3))
                            .shake(hz: 0.5, curve: Curves.easeInOut),
      
                        const SizedBox(height: 24),
      
                        Text(
                          Locales.current.unlock_premium,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.3, end: 0),
      
                        const SizedBox(height: 40),
      
                        // Storage animation
                        _buildStorageAnimation(),
      
                        const SizedBox(height: 40),
      
                        // Trial toggle
                        _buildTrialToggle(),
      
                        const SizedBox(height: 24),
      
                        // Pricing
                        _buildPricing(trialDate),
      
                        const SizedBox(height: 32),
      
                        // Start trial button
                        Container(
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                                ),
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFFFFD700).withOpacity(0.3),
                                    blurRadius: 20,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                              child: CupertinoButton(
                                padding: const EdgeInsets.symmetric(vertical: 18),
                                onPressed: _isLoading ? null : _startTrial,
                                child: _isLoading
                                    ? const CupertinoActivityIndicator(color: Colors.white)
                                    : Text(
                                        Locales.current.start_trial,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                              ),
                            )
                            .animate()
                            .fadeIn(delay: 400.ms, duration: 600.ms)
                            .slideY(begin: 0.3, end: 0),
      
                        const SizedBox(height: 16),
      
                        // Restore purchases button
                        CupertinoButton(
                          onPressed: _isLoading ? null : _restorePurchases,
                          child: Text(
                            Locales.current.restore_purchases,
                            style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 14),
                          ),
                        ),
      
                        const SizedBox(height: 24),
      
                        // Terms text
                        Text(
                          Locales.current.subscription_terms,
                          style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 12),
                          textAlign: TextAlign.center,
                        ),
      
                        const SizedBox(height: 40),
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

  Widget _buildStorageAnimation() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          // App icons row
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildAppIcon(CupertinoIcons.photo, Colors.blue),
              const SizedBox(width: 16),
              _buildAppIcon(CupertinoIcons.cloud, Colors.purple),
              const SizedBox(width: 16),
              _buildAppIcon(CupertinoIcons.folder, Colors.orange),
            ],
          ),

          const SizedBox(height: 24),

          // Storage progress bar
          AnimatedBuilder(
            animation: _storageAnimation,
            builder: (context, child) {
              return Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        Locales.current.storage,
                        style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 14),
                      ),
                      Text(
                        '${((_storageAnimation.value) * 100).toInt()}%',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: _storageAnimation.value,
                      backgroundColor: Colors.white.withOpacity(0.1),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Color.lerp(Colors.green, Colors.red, 1 - _storageAnimation.value)!,
                      ),
                      minHeight: 8,
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms, duration: 600.ms).slideY(begin: 0.2, end: 0);
  }

  Widget _buildAppIcon(IconData icon, Color color) {
    return Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.5), width: 2),
          ),
          child: Icon(icon, color: color, size: 30),
        )
        .animate(onPlay: (controller) => controller.repeat())
        .shimmer(duration: 2000.ms, color: Colors.white.withOpacity(0.2));
  }

  Widget _buildTrialToggle() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            Locales.current.trial_enabled,
            style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
          ),
          CupertinoSwitch(
            value: _isTrialEnabled,
            activeColor: const Color(0xFFFFD700),
            onChanged: (value) {
              setState(() => _isTrialEnabled = value);
            },
          ),
        ],
      ),
    ).animate().fadeIn(delay: 300.ms, duration: 600.ms).slideY(begin: 0.2, end: 0);
  }

  Widget _buildPricing(DateTime trialDate) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF6366F1).withOpacity(0.2),
            const Color(0xFF8B5CF6).withOpacity(0.2),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF6366F1).withOpacity(0.3), width: 2),
      ),
      child: Column(
        children: [
          const Text(
            '\$0.00',
            style: TextStyle(color: Colors.white, fontSize: 48, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            '${Locales.current.then} \$9.99 ${Locales.current.on} ${trialDate.day}/${trialDate.month}/${trialDate.year}',
            style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 14),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    ).animate().fadeIn(delay: 350.ms, duration: 600.ms).slideY(begin: 0.2, end: 0);
  }
}
