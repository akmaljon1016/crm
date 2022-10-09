import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:crm/cubit/completed_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart';

import 'cardview.dart';
import 'model/datum.dart';
import 'model/searchtovar.dart';
import 'model/tovar.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return BlocProvider<CompletedCubit>(
      create: (context) => CompletedCubit(),
      child: MaterialApp(
        title: 'CRM',
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        home: MyHomePage(),
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  bool connected = true;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final scrollController = ScrollController();
  int page = 1;
  bool isLoadingMore = false;
  List<Datum> zapchastlar = [];
  var myText = TextEditingController();
  bool success = false;

  ConnectivityResult _connectionStatus = ConnectivityResult.none;
  final Connectivity _connectivity = Connectivity();
  late StreamSubscription<ConnectivityResult> _connectivitySubscription;

  @override
  void initState() {
    super.initState();
//    items = Network().getItems(page);
    getItems(1);
    scrollController.addListener(_scrollListener);
    myText.addListener(handleChanges);
    initConnectivity();
    _connectivitySubscription =
        _connectivity.onConnectivityChanged.listen(_updateConnectionStatus);
    checkConnected();
  }

  @override
  void dispose() {
    _connectivitySubscription.cancel();
    super.dispose();
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initConnectivity() async {
    late ConnectivityResult result;
    try {
      result = await _connectivity.checkConnectivity();
    } on PlatformException catch (e) {
      return;
    }

    if (!mounted) {
      return Future.value(null);
    }

    return _updateConnectionStatus(result);
  }

  Future<void> _updateConnectionStatus(ConnectivityResult result) async {
    setState(() {
      _connectionStatus = result;
    });
  }

  @override
  Widget build(BuildContext context) {
    checkConnected();
    return Scaffold(
      appBar: AppBar(
        title: Text("CRM"),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          Navigator.pushReplacement(
              context,
              PageRouteBuilder(
                  pageBuilder: (a, b, c) => MyApp(),
                  transitionDuration: Duration(seconds: 0)));
        },
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.all(8.0),
              child: Container(
                height: 60,
                child: TextField(
                  controller: myText,
                  decoration: InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: "qidirish",
                      suffixIcon: IconButton(
                          onPressed: myText.clear, icon: Icon(Icons.clear))),
                ),
              ),
            ),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Container(
                    height: 40.0,
                    decoration: BoxDecoration(
                        border: Border.all(width: 1.0, color: Colors.black),
                        color: Colors.blue),
                    child: const Center(
                        child: Text(
                      "Nomi",
                      style: TextStyle(color: Colors.white),
                    )),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Container(
                    height: 40.0,
                    decoration: BoxDecoration(
                        border: Border.all(width: 1.0, color: Colors.black),
                        color: Colors.blue),
                    child: const Center(
                        child: Text(
                      "Olish Narxi",
                      style: TextStyle(color: Colors.white),
                    )),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Container(
                    height: 40.0,
                    decoration: BoxDecoration(
                        border: Border.all(width: 1.0, color: Colors.black),
                        color: Colors.blue),
                    child: const Center(
                        child: Text(
                      "Foiz",
                      style: TextStyle(color: Colors.white),
                    )),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Container(
                    height: 40.0,
                    decoration: BoxDecoration(
                        border: Border.all(width: 1.0, color: Colors.black),
                        color: Colors.blue),
                    child: const Center(
                        child: Text(
                      "Sotish Narxi ",
                      style: TextStyle(color: Colors.white),
                    )),
                  ),
                ),
              ],
            ),
            Expanded(child: mainContainer()),
            Visibility(visible: widget.connected, child: Text("No Internet"))
          ],
        ),
      ),
    );
  }

  void checkConnected() {
    if (_connectionStatus.toString() == "ConnectivityResult.none") {
      widget.connected = true;
    } else {
      widget.connected = false;
    }
  }

  Widget mainContainer() {
    if (zapchastlar.isEmpty) {
      if (success) {
        return const Center(
          child: Text("Hech nima topilmadi"),
        );
      } else {
        return const Center(
          child: CircularProgressIndicator(),
        );
      }
    } else {
      return getTaskListview();
    }
  }

  Future<void> getItems(int page) async {
    var url = "http://umidhoja.ga/api/tovarlar?page=${page}";
    var response = await get(Uri.parse(url));
    print(url);
    if (response.statusCode == 200) {
      final json = tovarFromJson(response.body);
      setState(() {
        zapchastlar = zapchastlar + json.data;
      });
    }
    throw Exception("");
  }

  Future<void> search(
    String text,
  ) async {
    var url = "http://umidhoja.ga/api/search?query=${text}";
    print(url);
    var response = await get(Uri.parse(url));
    if (response.statusCode == 200) {
      final json = searchFromJson(response.body);
      setState(() {
        zapchastlar = zapchastlar + json.data;
        success = true;
        //BlocProvider.of<CompletedCubit>(context).completed(true);
      });
    } else {
      setState(() {
        success = false;
        //BlocProvider.of<CompletedCubit>(context).completed(true);
      });
    }
  }

  Future<void> _scrollListener() async {
    if (scrollController.position.pixels ==
        scrollController.position.maxScrollExtent) {
      page = page + 1;
      setState(() {
        isLoadingMore = true;
      });
      if (myText.value.text.toString().isEmpty) {
        await getItems(page);
      }
      isLoadingMore = false;
    }
  }

  void handleChanges() {
    zapchastlar.clear();
    if (myText.value.text.toString() == "") {
      getItems(1);
    } else {
      search(myText.value.text.toString());
    }
  }

  Widget getTaskListview() {
    return ListView.builder(
        padding: const EdgeInsets.only(bottom: 12.0),
        controller: scrollController,
        itemCount: isLoadingMore ? zapchastlar.length + 1 : zapchastlar.length,
        itemBuilder: (BuildContext context, int index) {
          if (index < zapchastlar.length) {
            return CardView(zapchastlar[index]);
          } else {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }
        });
  }
}
