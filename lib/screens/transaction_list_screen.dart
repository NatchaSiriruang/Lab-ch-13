// lib/screens/transaction_list_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/transaction_provider.dart';
import '../models/my_transaction.dart';

class TransactionListScreen extends StatelessWidget {
  const TransactionListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('รายรับ-รายจ่าย'),
        // ความท้าทายข้อ 2: แถบยอดคงเหลือใต้ AppBar
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(40),
          child: Consumer<TransactionProvider>(
            builder: (context, txProvider, child) => SizedBox(
              height: 40,
              child: Center(
                child: Text(
                  'ยอดคงเหลือ: ${txProvider.balance.toStringAsFixed(2)} บาท',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: txProvider.balance >= 0 ? Colors.green : Colors.red,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
      body: Consumer<TransactionProvider>(
        builder: (context, txProvider, child) => txProvider.transactions.isEmpty
            ? const Center(child: Text('ไม่มีรายการ'))
            : ListView.builder(
                itemCount: txProvider.transactions.length,
                itemBuilder: (ctx, i) {
                  final tx = txProvider.transactions[i];
                  return ListTile(
                    leading: CircleAvatar(
                      child: Text(
                        tx.type == TransactionType.income ? 'รับ' : 'จ่าย',
                      ),
                    ),
                    title: Text(tx.title),
                    subtitle: Text(DateFormat.yMMMd().format(tx.date)),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${tx.amount.toStringAsFixed(2)} บาท',
                          style: TextStyle(
                            color: tx.type == TransactionType.income
                                ? Colors.green
                                : Colors.red,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.grey),
                          onPressed: () {
                            // เรียกเมธอด delete
                            context
                                .read<TransactionProvider>()
                                .deleteTransaction(tx.id!);
                          },
                        ),
                      ],
                    ),
                  );
                },
              ),
      ),
      // ความท้าทายข้อ 3: ปุ่มนำเข้า 100 รายการ + ปุ่มเพิ่มรายการเดียว
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton.small(
            heroTag: 'one',
            tooltip: 'นำเข้า 100 รายการ (ทีละรายการ)',
            onPressed: () async {
              final ms = await context
                  .read<TransactionProvider>()
                  .importOneByOne();
              if (!context.mounted) return;
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text('ทีละรายการ: $ms ms')));
            },
            child: const Icon(Icons.looks_one),
          ),
          const SizedBox(height: 8),
          FloatingActionButton.small(
            heroTag: 'batch',
            tooltip: 'นำเข้า 100 รายการ (batch)',
            onPressed: () async {
              final ms = await context
                  .read<TransactionProvider>()
                  .importWithBatch();
              if (!context.mounted) return;
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text('batch: $ms ms')));
            },
            child: const Icon(Icons.bolt),
          ),
          const SizedBox(height: 8),
          FloatingActionButton(
            heroTag: 'add',
            onPressed: () => context.read<TransactionProvider>().addTransaction(
              'ค่าอาหาร',
              120.0,
              DateTime.now(),
              TransactionType.expense,
            ),
            child: const Icon(Icons.add),
          ),
        ],
      ),
    );
  }
}
