import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:spare_kart/core/theme/app_colors.dart';
import 'package:spare_kart/core/theme/app_decorations.dart';
import 'package:spare_kart/core/utils/responsive.dart';
import 'package:spare_kart/data/models/chat_payment.dart';
import 'package:spare_kart/data/repositories/chat_payment_repository.dart';
import 'package:spare_kart/features/messages/chat_flow.dart';

class AdminPaymentsScreen extends StatefulWidget {
  const AdminPaymentsScreen({super.key});

  @override
  State<AdminPaymentsScreen> createState() => _AdminPaymentsScreenState();
}

class _AdminPaymentsScreenState extends State<AdminPaymentsScreen> {
  final _repository = ChatPaymentRepository();
  List<ChatPayment> _payments = [];
  bool _loading = true;
  String? _error;
  final Set<String> _expanded = {};
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
      final payments = await _repository.fetchAllPayments();
      if (!mounted) return;
      setState(() {
        _payments = payments;
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

  Future<void> _approveRefund(ChatPayment payment) async {
    setState(() => _approving.add(payment.id));
    try {
      await _repository.approveRefund(payment.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Refund approved via Razorpay.')),
      );
      await _load();
    } on ChatPaymentException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    } finally {
      if (mounted) setState(() => _approving.remove(payment.id));
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

    if (_payments.isEmpty) {
      return const Center(
        child: Text(
          'No Razorpay payments yet.',
          style: TextStyle(color: AppColors.textSecondary),
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
        itemCount: _payments.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (context, index) => _PaymentCard(
          payment: _payments[index],
          expanded: _expanded.contains(_payments[index].id),
          isApproving: _approving.contains(_payments[index].id),
          onToggle: () {
            setState(() {
              final id = _payments[index].id;
              if (_expanded.contains(id)) {
                _expanded.remove(id);
              } else {
                _expanded.add(id);
              }
            });
          },
          onApproveRefund: _payments[index].status == ChatPaymentStatus.refundRequested
              ? () => _approveRefund(_payments[index])
              : null,
        ),
      ),
    );
  }
}

class _PaymentCard extends StatelessWidget {
  const _PaymentCard({
    required this.payment,
    required this.expanded,
    required this.isApproving,
    required this.onToggle,
    this.onApproveRefund,
  });

  final ChatPayment payment;
  final bool expanded;
  final bool isApproving;
  final VoidCallback onToggle;
  final VoidCallback? onApproveRefund;

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('d MMM yyyy, h:mm a');

    return Container(
      decoration: AppDecorations.card(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: onToggle,
            borderRadius: BorderRadius.circular(AppDecorations.radiusLg),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          payment.partTitle.isNotEmpty
                              ? payment.partTitle
                              : 'Chat payment',
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      _StatusChip(status: payment.status),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Advance token: ${ChatFlow.formatPrice(payment.tokenAmount)} (1%)',
                    style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Agreed price: ${ChatFlow.formatPrice(payment.agreedPrice)}',
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${payment.buyerName} → ${payment.sellerName}',
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                  if (payment.createdAt != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      dateFormat.format(payment.createdAt!.toLocal()),
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        expanded ? 'Hide Razorpay details' : 'Show Razorpay details',
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                      Icon(
                        expanded ? Icons.expand_less : Icons.expand_more,
                        color: AppColors.primary,
                        size: 20,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (expanded) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _detailRow('Payment record ID', payment.id),
                  _detailRow('Thread ID', payment.threadId),
                  if (payment.listingId != null) _detailRow('Listing ID', payment.listingId!),
                  _detailRow('Buyer ID', payment.buyerId),
                  _detailRow('Seller ID', payment.sellerId),
                  _detailRow('Amount (paise)', '${payment.amountPaise}'),
                  _detailRow('Currency', payment.currency),
                  _detailRow('Token percent', '${(payment.tokenPercent * 100).toStringAsFixed(0)}%'),
                  if (payment.razorpayOrderId != null)
                    _detailRow('Razorpay order ID', payment.razorpayOrderId!),
                  if (payment.razorpayPaymentId != null)
                    _detailRow('Razorpay payment ID', payment.razorpayPaymentId!),
                  if (payment.razorpayReceipt != null)
                    _detailRow('Receipt', payment.razorpayReceipt!),
                  if (payment.paymentMethod != null && payment.paymentMethod!.isNotEmpty)
                    _detailRow('Payment method', payment.paymentMethod!),
                  if (payment.razorpayPaymentStatus != null)
                    _detailRow('Razorpay status', payment.razorpayPaymentStatus!),
                  if (payment.paidAt != null)
                    _detailRow('Paid at', dateFormat.format(payment.paidAt!.toLocal())),
                  if (payment.refundReason != null && payment.refundReason!.isNotEmpty)
                    _detailRow('Refund reason', payment.refundReason!),
                  if (payment.razorpayRefundId != null)
                    _detailRow('Razorpay refund ID', payment.razorpayRefundId!),
                  if (payment.razorpayOrderResponse.isNotEmpty)
                    _jsonBlock('Order response', payment.razorpayOrderResponse),
                  if (payment.razorpayPaymentResponse.isNotEmpty)
                    _jsonBlock('Payment response', payment.razorpayPaymentResponse),
                  if (payment.razorpayWebhookEvents.isNotEmpty)
                    _jsonBlock('Webhook events', payment.razorpayWebhookEvents),
                  if (payment.razorpayRefundResponse != null)
                    _jsonBlock('Refund response', payment.razorpayRefundResponse!),
                  if (onApproveRefund != null) ...[
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      onPressed: isApproving ? null : onApproveRefund,
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
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _jsonBlock(String title, Object data) {
    final encoder = const JsonEncoder.withIndent('  ');
    final text = data is Map || data is List
        ? encoder.convert(data)
        : data.toString();

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          const SizedBox(height: 6),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.chipBg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: SelectableText(
              text,
              style: const TextStyle(fontSize: 11, fontFamily: 'monospace'),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final ChatPaymentStatus status;

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      ChatPaymentStatus.paid => AppColors.success,
      ChatPaymentStatus.refundRequested => AppColors.warning,
      ChatPaymentStatus.refunded => AppColors.textSecondary,
      ChatPaymentStatus.failed => AppColors.error,
      ChatPaymentStatus.pending => AppColors.primary,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.label,
        style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }
}
