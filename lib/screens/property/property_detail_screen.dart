import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../config/constants.dart';
import '../../config/theme.dart';
import '../../models/transaction_payment.dart';
import '../../providers/property_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../models/transaction.dart';
import '../../utils/balance_calculator.dart';
import '../../utils/formatters.dart';

class PropertyDetailScreen extends ConsumerStatefulWidget {
  final String propertyId;

  const PropertyDetailScreen({super.key, required this.propertyId});

  @override
  ConsumerState<PropertyDetailScreen> createState() =>
      _PropertyDetailScreenState();
}

class _PropertyDetailScreenState extends ConsumerState<PropertyDetailScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final propertiesAsync = ref.watch(propertiesProvider);

    return propertiesAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => Scaffold(
        appBar: AppBar(title: const Text('Property')),
        body: Center(child: Text('Error: $error')),
      ),
      data: (properties) {
        final property = properties.firstWhere(
          (p) => p.id == widget.propertyId,
        );

        return Scaffold(
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => context.pop(),
            ),
            title: Text(property.name),
            bottom: TabBar(
              controller: _tabController,
              labelColor: AppTheme.primaryColor,
              unselectedLabelColor: AppTheme.textSecondary,
              indicatorColor: AppTheme.primaryColor,
              tabs: const [
                Tab(text: 'Overview'),
                Tab(text: 'Balances'),
                Tab(text: 'Transactions'),
              ],
            ),
          ),
          floatingActionButton: FloatingActionButton(
            backgroundColor: AppTheme.primaryColor,
            foregroundColor: Colors.white,
            onPressed: () {
              context.push('/property/${widget.propertyId}/add-transaction');
            },
            child: const Icon(Icons.add),
          ),
          body: TabBarView(
            controller: _tabController,
            children: [
              _OverviewTab(propertyId: widget.propertyId),
              _BalancesTab(propertyId: widget.propertyId),
              _TransactionsTab(propertyId: widget.propertyId),
            ],
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Overview Tab
// ---------------------------------------------------------------------------

class _OverviewTab extends ConsumerWidget {
  final String propertyId;
  const _OverviewTab({required this.propertyId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final propertiesAsync = ref.watch(propertiesProvider);
    final valuationAsync = ref.watch(valuationProvider(propertyId));
    final mortgageAsync = ref.watch(mortgageProvider(propertyId));
    final investorsAsync = ref.watch(investorsProvider(propertyId));
    final allTxnAsync = ref.watch(allTransactionsProvider(propertyId));

    final property = propertiesAsync.valueOrNull?.firstWhere(
      (p) => p.id == propertyId,
    );

    if (property == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final valuation = valuationAsync.valueOrNull;
    final mortgage = mortgageAsync.valueOrNull;
    final investors = investorsAsync.valueOrNull;
    final allTxns = allTxnAsync.valueOrNull;

    final currentValue = valuation?.currentValue ?? property.purchasePrice;
    final mortgageBalance = mortgage?.balance ?? 0.0;
    final netEquity = currentValue - mortgageBalance;

    // Calculate ownership from transactions if data is available
    String ownershipDisplay = '--';
    if (investors != null && allTxns != null) {
      // We need payments but we show a simplified view here;
      // ownership falls back to plannedContribution when no payments loaded.
      final ownership = BalanceCalculator.calculateOwnership(
        investors: investors,
        allTransactions: allTxns,
        paymentsByTransaction: const {},
      );
      // Show total of all investors' ownership (should be ~100%) is not useful;
      // instead show each investor's share in a sub-list.
      ownershipDisplay = investors
          .map((inv) =>
              '${inv.name}: ${Formatters.percentage(ownership[inv.id] ?? inv.plannedContribution)}')
          .join('\n');
    }

    final isLoading = valuationAsync.isLoading ||
        mortgageAsync.isLoading ||
        investorsAsync.isLoading;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _InfoCard(
          title: 'Property Value',
          children: [
            _InfoRow(
              label: 'Purchase Price',
              value: Formatters.currency(property.purchasePrice,
                  currency: property.currency),
            ),
            _InfoRow(
              label: 'Current Valuation',
              value: valuationAsync.isLoading
                  ? '...'
                  : Formatters.currency(currentValue,
                      currency: property.currency),
            ),
            _InfoRow(
              label: 'Net Equity',
              value: isLoading
                  ? '...'
                  : Formatters.currency(netEquity,
                      currency: property.currency),
              valueColor: netEquity >= 0
                  ? AppTheme.successColor
                  : AppTheme.errorColor,
            ),
          ],
        ),
        const SizedBox(height: 16),
        _InfoCard(
          title: 'Mortgage',
          children: [
            _InfoRow(
              label: 'Balance',
              value: mortgageAsync.isLoading
                  ? '...'
                  : mortgage != null
                      ? Formatters.currency(mortgageBalance,
                          currency: property.currency)
                      : 'No mortgage',
            ),
            if (mortgage != null) ...[
              _InfoRow(
                label: 'Rate',
                value:
                    '${mortgage.rate.toStringAsFixed(2)}% (${mortgage.rateType})',
              ),
              _InfoRow(
                label: 'Payment',
                value:
                    '${Formatters.currency(mortgage.payment, currency: property.currency)} / ${mortgage.frequency}',
              ),
            ],
          ],
        ),
        const SizedBox(height: 16),
        _InfoCard(
          title: 'Ownership',
          children: [
            if (investorsAsync.isLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              )
            else if (investors != null)
              ...investors.map((inv) {
                final pct = BalanceCalculator.calculateOwnership(
                  investors: investors,
                  allTransactions: allTxns ?? [],
                  paymentsByTransaction: const {},
                )[inv.id] ??
                    inv.plannedContribution;
                return _InfoRow(
                  label: inv.name,
                  value: Formatters.percentage(pct),
                );
              }),
          ],
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Balances Tab
// ---------------------------------------------------------------------------

class _BalancesTab extends ConsumerStatefulWidget {
  final String propertyId;
  const _BalancesTab({required this.propertyId});

  @override
  ConsumerState<_BalancesTab> createState() => _BalancesTabState();
}

class _BalancesTabState extends ConsumerState<_BalancesTab> {
  Map<String, List<TransactionPayment>>? _paymentsByTransaction;
  bool _loadingPayments = false;

  @override
  Widget build(BuildContext context) {
    final investorsAsync = ref.watch(investorsProvider(widget.propertyId));
    final allTxnAsync = ref.watch(allTransactionsProvider(widget.propertyId));

    return investorsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (investors) => allTxnAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (allTransactions) {
          _loadPaymentsIfNeeded(allTransactions);

          if (_loadingPayments || _paymentsByTransaction == null) {
            return const Center(child: CircularProgressIndicator());
          }

          final balances = BalanceCalculator.calculateBalances(
            investors: investors,
            allTransactions: allTransactions,
            paymentsByTransaction: _paymentsByTransaction!,
          );

          if (balances.isEmpty) {
            return const Center(
              child: Text(
                'No investors found',
                style: TextStyle(color: AppTheme.textSecondary),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: balances.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final b = balances[index];
              return _BalanceCard(balance: b);
            },
          );
        },
      ),
    );
  }

  void _loadPaymentsIfNeeded(List<Transaction> allTransactions) {
    if (_paymentsByTransaction != null || _loadingPayments) return;
    _loadingPayments = true;

    final txnService = ref.read(transactionServiceProvider);

    Future(() async {
      final map = <String, List<TransactionPayment>>{};
      for (final txn in allTransactions) {
        final payments = await txnService.getTransactionPayments(txn.id);
        map[txn.id] = payments;
      }
      if (mounted) {
        setState(() {
          _paymentsByTransaction = map;
          _loadingPayments = false;
        });
      }
    });
  }
}

class _BalanceCard extends StatelessWidget {
  final InvestorBalance balance;
  const _BalanceCard({required this.balance});

  @override
  Widget build(BuildContext context) {
    Color balanceColor;
    String balanceLabel;

    if (balance.owes) {
      balanceColor = AppTheme.owesColor;
      balanceLabel = 'Owes';
    } else if (balance.isOwed) {
      balanceColor = AppTheme.owedColor;
      balanceLabel = 'Owed';
    } else {
      balanceColor = AppTheme.textMuted;
      balanceLabel = 'Settled';
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  balance.investor.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: balanceColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    balanceLabel,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: balanceColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _BalanceStat(
                    label: 'Planned',
                    value: Formatters.percentage(
                        balance.investor.plannedContribution),
                  ),
                ),
                Expanded(
                  child: _BalanceStat(
                    label: 'Ownership',
                    value: Formatters.percentage(balance.ownershipPercent),
                  ),
                ),
                Expanded(
                  child: _BalanceStat(
                    label: 'Balance',
                    value: Formatters.currency(balance.expenseBalance.abs()),
                    valueColor: balanceColor,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _BalanceStat extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _BalanceStat({
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppTheme.textSecondary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: valueColor ?? AppTheme.textPrimary,
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Transactions Tab
// ---------------------------------------------------------------------------

class _TransactionsTab extends ConsumerWidget {
  final String propertyId;
  const _TransactionsTab({required this.propertyId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final txnAsync = ref.watch(transactionsProvider(propertyId));
    final investorsAsync = ref.watch(investorsProvider(propertyId));

    return txnAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (transactions) {
        if (transactions.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Text(
                'No transactions yet',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 16),
              ),
            ),
          );
        }

        final investorMap = <String, String>{};
        final investors = investorsAsync.valueOrNull;
        if (investors != null) {
          for (final inv in investors) {
            investorMap[inv.id] = inv.name;
          }
        }

        return ListView.separated(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: transactions.length,
          separatorBuilder: (_, __) => const Divider(
            indent: 16,
            endIndent: 16,
          ),
          itemBuilder: (context, index) {
            final txn = transactions[index];
            return _TransactionTile(
              transaction: txn,
              investorName: txn.paidBy != null
                  ? investorMap[txn.paidBy] ?? 'Unknown'
                  : null,
            );
          },
        );
      },
    );
  }
}

class _TransactionTile extends StatelessWidget {
  final Transaction transaction;
  final String? investorName;

  const _TransactionTile({
    required this.transaction,
    this.investorName,
  });

  Color _categoryColor(String category) {
    if (AppConstants.incomeCategories.contains(category)) {
      return AppTheme.successColor;
    }
    if (AppConstants.capitalCategories.contains(category)) {
      return AppTheme.primaryColor;
    }
    if (AppConstants.mortgageCategories.contains(category)) {
      return AppTheme.warningColor;
    }
    // expense
    return AppTheme.errorColor;
  }

  IconData _categoryIcon(String category) {
    switch (category) {
      case 'down-payment':
        return Icons.account_balance_wallet;
      case 'rental':
        return Icons.home_work;
      case 'other-income':
        return Icons.attach_money;
      case 'property-tax':
        return Icons.receipt_long;
      case 'insurance':
        return Icons.shield;
      case 'strata':
        return Icons.apartment;
      case 'utilities':
        return Icons.bolt;
      case 'maintenance':
        return Icons.build;
      case 'closing-costs':
        return Icons.gavel;
      case 'renovation':
        return Icons.construction;
      case 'legal':
        return Icons.balance;
      case 'mortgage':
      case 'mortgage-principal':
      case 'mortgage-interest':
      case 'mortgage-insurance':
      case 'mortgage-prepayment':
        return Icons.account_balance;
      default:
        return Icons.receipt;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _categoryColor(transaction.category);
    final icon = _categoryIcon(transaction.category);
    final label = AppConstants.categoryLabel(transaction.category);

    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
          Text(
            Formatters.currency(transaction.amount),
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: color,
            ),
          ),
        ],
      ),
      subtitle: Row(
        children: [
          Expanded(
            child: Text(
              [
                Formatters.date(transaction.transactionDate),
                if (investorName != null) investorName!,
              ].join(' \u2022 '),
              style: const TextStyle(
                fontSize: 12,
                color: AppTheme.textSecondary,
              ),
            ),
          ),
          if (transaction.hasDocument)
            const Icon(
              Icons.description,
              size: 16,
              color: AppTheme.textMuted,
            ),
        ],
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      dense: true,
      onTap: transaction.description != null && transaction.description!.isNotEmpty
          ? () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(transaction.description!)),
              );
            }
          : null,
    );
  }
}

// ---------------------------------------------------------------------------
// Shared Widgets
// ---------------------------------------------------------------------------

class _InfoCard extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _InfoCard({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _InfoRow({
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: AppTheme.textSecondary,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: valueColor ?? AppTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
