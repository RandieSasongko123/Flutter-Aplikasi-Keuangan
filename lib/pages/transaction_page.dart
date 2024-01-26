import 'package:aplikasi_keuangan/models/database.dart';
import 'package:aplikasi_keuangan/models/transaction_with_category.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class TransactionPage extends StatefulWidget {
  final TransactionWithCategory? transactionWithCategory;
  const TransactionPage({
    Key? key,
    required this.transactionWithCategory,
  }) : super(key: key);

  @override
  State<TransactionPage> createState() => _TransactionPageState();
}

class _TransactionPageState extends State<TransactionPage> {
  bool isExpense = true;
  List<String> list = ['Makan dan Jajan', 'Transportasi', 'Nonton Film'];
  late String dropDownValue = list.first;
  late int type;

  TextEditingController amountController = TextEditingController();
  TextEditingController detailController = TextEditingController();
  TextEditingController dateController = TextEditingController();

  Category? selectedCategory;

  final AppDb database = AppDb();

  Future insert(
      int amount, DateTime date, String nameDetail, int categoryId) async {
    // ada insert to database
    DateTime now = DateTime.now();
    final row = await database.into(database.transactions).insertReturning(
          TransactionsCompanion.insert(
              name: nameDetail,
              category_id: categoryId,
              transaction_date: date,
              amount: amount,
              createdAt: now,
              updatedAt: now),
        );
    print(row);
  }

  Future<List<Category>> getAllCategory(int type) async {
    return await database.getAllCategoryRepo(type);
  }

  Future update(int transactionId, int amount, int categoryId,
      DateTime transactionDate, String nameDetail) async {
    return await database.updateTransactionRepo(
        transactionId, amount, categoryId, transactionDate, nameDetail);
  }

  Future delete(int transactionId) async {
    return await database.deleteTransactionRepo(transactionId);
  }

  @override
  void initState() {
    if (widget.transactionWithCategory != null) {
      updateTransactionView(widget.transactionWithCategory!);
    } else {
      type = 2;
    }

    super.initState();
  }

  void updateTransactionView(TransactionWithCategory transactionWithCategory) {
    amountController.text =
        transactionWithCategory.transaction.amount.toString();
    detailController.text = transactionWithCategory.transaction.name;
    dateController.text = DateFormat("yyyy-MM-dd")
        .format(transactionWithCategory.transaction.transaction_date);
    type = transactionWithCategory.category.type;
    (type == 2) ? isExpense = true : isExpense = false;
    selectedCategory = transactionWithCategory.category;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Add Trasaction"),
      ),
      body: SingleChildScrollView(
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 0),
                child: Row(
                  children: [
                    Switch(
                      value: isExpense,
                      onChanged: (bool value) {
                        setState(() {
                          isExpense = value;
                          type = (isExpense) ? 2 : 1;
                          selectedCategory = null;
                        });
                      },
                      inactiveTrackColor: Colors.green[200],
                      inactiveThumbColor: Colors.green,
                      activeColor: Colors.red,
                    ),
                    SizedBox(
                      width: 3,
                    ),
                    Text(
                      isExpense ? "Expense" : "Income",
                      style: GoogleFonts.montserrat(fontSize: 18),
                    )
                  ],
                ),
              ),
              SizedBox(
                height: 10,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: TextFormField(
                  controller: amountController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                      border: UnderlineInputBorder(), labelText: "Amount"),
                ),
              ),
              SizedBox(
                height: 20,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Text(
                  'Category',
                  style: GoogleFonts.montserrat(fontSize: 16),
                ),
              ),
              FutureBuilder<List<Category>>(
                future: getAllCategory(type),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(
                      child: CircularProgressIndicator(),
                    );
                  } else {
                    if (snapshot.hasData) {
                      if (snapshot.data!.length > 0) {
                        // print('::: ' + snapshot.toString());
                        selectedCategory = (selectedCategory == null)
                            ? snapshot.data!.first
                            : selectedCategory;
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: DropdownButton<Category>(
                              isExpanded: true,
                              value: (selectedCategory == null)
                                  ? snapshot.data!.first
                                  : selectedCategory,
                              icon: Icon(Icons.arrow_downward),
                              items: snapshot.data!.map((Category item) {
                                return DropdownMenuItem<Category>(
                                  value: item,
                                  child: Text(item.name),
                                );
                              }).toList(),
                              onChanged: (Category? value) {
                                setState(() {
                                  selectedCategory = value;
                                });
                              }),
                        );
                      } else {
                        return Center(
                          child: Text("Data Kosong"),
                        );
                      }
                    } else {
                      return Center(
                        child: Text("Tidak ada data"),
                      );
                    }
                  }
                },
              ),
              SizedBox(
                height: 20,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: TextFormField(
                  readOnly: true,
                  controller: dateController,
                  decoration: InputDecoration(labelText: "Enter Date"),
                  onTap: () async {
                    DateTime? pickedDate = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime(1945),
                      lastDate: DateTime(2045),
                    );

                    if (pickedDate != null) {
                      String formattedDate =
                          DateFormat('yyyy-MM-dd').format(pickedDate);

                      dateController.text = formattedDate;
                    }
                  },
                ),
              ),
              SizedBox(
                height: 25,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: TextFormField(
                  controller: detailController,
                  decoration: InputDecoration(
                      border: UnderlineInputBorder(), labelText: "Detail"),
                ),
              ),
              SizedBox(
                height: 25,
              ),
              Center(
                  child: ElevatedButton(
                      onPressed: () async {
                        (widget.transactionWithCategory == null)
                            ? insert(
                                int.parse(amountController.text),
                                DateTime.parse(dateController.text),
                                detailController.text,
                                selectedCategory!.id)
                            : update(
                                widget.transactionWithCategory!.transaction.id,
                                int.parse(amountController.text),
                                selectedCategory!.id,
                                DateTime.parse(dateController.text),
                                detailController.text);
                        Navigator.pop(context, true);

                        setState(() {});
                        print('amount : ' + amountController.text);
                        print('date : ' + dateController.text);
                        print('detail : ' + detailController.text);
                      },
                      child: Text("Save")))
            ],
          ),
        ),
      ),
    );
  }
}
