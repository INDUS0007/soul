import 'package:flutter/material.dart';

import 'package:common/api/api_client.dart';
import 'package:common/widgets/widgets.dart';

class WalletPage extends StatefulWidget {
  const WalletPage({super.key});

  @override
  State<WalletPage> createState() => _WalletPageState();
}

class _WalletPageState extends State<WalletPage> {
  final ApiClient _api = ApiClient();
  final TextEditingController _customCtrl = TextEditingController();

  bool _loading = true;
  bool _recharging = false;
  String? _error;
  int _walletAmount = 0;
  int _selectedAmount = 100;
  bool _isLoading = false;  // Track if a load is in progress
  bool _hasLoadedOnce = false;  // Track if we've loaded at least once

  @override
  void initState() {
    super.initState();
    // Always load fresh wallet data when page opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadWallet();
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Refresh wallet when page becomes visible (e.g., when navigating back to it)
    // This ensures balance is up-to-date after transactions
    // Only refresh if we've already loaded once (to avoid double-loading on first mount)
    if (_hasLoadedOnce) {
      final route = ModalRoute.of(context);
      if (route != null && route.isCurrent && !_isLoading) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && !_isLoading) {
            _loadWallet();
          }
        });
      }
    }
  }

  @override
  void dispose() {
    _customCtrl.dispose();
    super.dispose();
  }
  
  Future<void> _loadWallet() async {
    // Prevent multiple simultaneous loads
    if (_isLoading) return;
    
    _isLoading = true;
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final wallet = await _api.getWallet();
      if (!mounted) {
        _isLoading = false;
        return;
      }
      setState(() {
        _walletAmount = wallet.amount;
        _loading = false;
        _isLoading = false;
        _hasLoadedOnce = true;
      });
    } on ApiClientException catch (error) {
      if (!mounted) {
        _isLoading = false;
        return;
      }
      setState(() {
        _error = error.message;
        _loading = false;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) {
        _isLoading = false;
        return;
      }
      setState(() {
        _error = 'Unable to load wallet. Please try again. ($error)';
        _loading = false;
        _isLoading = false;
      });
    }
  }

  Future<void> _recharge() async {
    if (_recharging) return;

    setState(() {
      _recharging = true;
    });

    try {
      final updatedAmount = await _api.rechargeWallet(_selectedAmount);
      if (!mounted) return;
      setState(() {
        _walletAmount = updatedAmount;
        _recharging = false;
      });
      showSuccessSnackBar(context, 'Wallet recharged successfully!');
    } on ApiClientException catch (error) {
      if (!mounted) return;
      setState(() => _recharging = false);
      showErrorSnackBar(context, error.message);
    } catch (error) {
      if (!mounted) return;
      setState(() => _recharging = false);
      showErrorSnackBar(context, 'Recharge failed. Please try again. ($error)');
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          Navigator.pop(context, _walletAmount);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          leading: BackButton(
            onPressed: () => Navigator.pop(context, _walletAmount),
          ),
          title: const Text('Wallet'),
          backgroundColor: const Color(0xFF8B5FBF),
        ),
        body: RefreshIndicator(
          onRefresh: _loadWallet,
          child: SafeArea(
            child: _buildBody(),
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.7,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _error!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: _loadWallet,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Current Balance',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.black54,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.refresh, size: 20),
                        color: const Color(0xFF8B5FBF),
                        onPressed: _loadWallet,
                        tooltip: 'Refresh balance',
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '₹$_walletAmount',
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF8B5FBF),
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Chat: ₹1 per minute',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Recharge Amount',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: [100, 500, 1000, 2000].map((amount) {
              final selected = _selectedAmount == amount;
              return ChoiceChip(
                label: Text('₹$amount'),
                selected: selected,
                onSelected: (_) {
                  setState(() {
                    _selectedAmount = amount;
                    _customCtrl.clear();
                  });
                },
                selectedColor: const Color(0xFF8B5FBF),
                labelStyle: TextStyle(
                  color: selected ? Colors.white : Colors.black,
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _customCtrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Custom amount (₹)',
              border: OutlineInputBorder(),
              isDense: true,
            ),
            onChanged: (value) {
              final parsed = int.tryParse(value);
              if (parsed != null && parsed > 0) {
                setState(() => _selectedAmount = parsed);
              }
            },
          ),
          const SizedBox(height: 24),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _recharging ? null : _recharge,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF8B5FBF),
              ),
              child: _recharging
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text('Recharge ₹$_selectedAmount'),
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
      ),
    );
  }
}


