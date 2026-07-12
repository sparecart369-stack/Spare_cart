import 'package:flutter/material.dart';
import 'package:spare_kart/core/theme/app_colors.dart';
import 'package:spare_kart/core/theme/app_decorations.dart';
import 'package:spare_kart/core/utils/responsive.dart';
import 'package:spare_kart/data/models/chat_payment.dart';
import 'package:spare_kart/data/repositories/chat_payment_repository.dart';
import 'package:spare_kart/features/messages/chat_flow.dart';

class AdminRefundsScreen extends StatefulWidget {
  const AdminRefundsScreen({super.key});

  @override
  State<AdminRefundsScreen> createState() => _AdminRefundsScreenState();
}

class _AdminRefundsScreenState extends State<AdminRefundsScreen> {
  final _repository = ChatPaymentRepository();
  List<ChatPayment> _requests = [];
  bool _loading = true;
  String? _error;
  final Set<String> _approving = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final requests = await _repository.fetchRefundRequests();
      if (!mounted) return;
      setState(() {
        _requests = requests;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString();
        _loading = false;
      });
    }
  }

  Future<void> _approve(ChatPayment payment) async {
    setState(() => _approving.add(payment.id));
    try {
      await _repository.approveRefund(payment.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Refund approved and processed via Razorpay.')),
      );
      await _load();
    } on ChatPaymentException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    } finally {
      if (mounted) {
        setState(() => _approving.remove(payment.id));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final r = Responsive(context);

    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(r.horizontalPadding()),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              FilledButton(onPressed: _load, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }

    if (_requests.isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(r.horizontalPadding()),
          child: const Text(
            'No refund requests right now.',
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: EdgeInsets.fromLTRB(
          r.horizontalPadding(),
          16,
          r.horizontalPadding(),
          24,
        ),
        itemCount: _requests.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final payment = _requests[index];
          final isApproving = _approving.contains(payment.id);

          return Container(
            padding: const EdgeInsets.all(16),
            decoration: AppDecorations.card(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Token ${ChatFlow.formatPrice(payment.tokenAmount)}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Agreed price: ${ChatFlow.formatPrice(payment.agreedPrice)}',
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
                if (payment.refundReason?.trim().isNotEmpty == true) ...[
                  const SizedBox(height: 8),
                  Text(
                    payment.refundReason!,
                    style: const TextStyle(fontSize: 13),
                  ),
                ],
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: isApproving ? null : () => _approve(payment),
                  icon: isApproving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.check_circle_outline_rounded),
                  label: Text(isApproving ? 'Approving...' : 'Approve refund'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
