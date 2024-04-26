import 'package:src/blocs/auth/auth.bloc.dart';
import 'package:src/shared/custom_components.dart';
import 'package:src/shared/custom_style.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:src/models/datamodel.dart';
import 'package:src/blocs/validators.dart';

class Appointments extends StatefulWidget {
  static const routeName = '/appointments';
  @override
  AppointmentsState createState() => AppointmentsState();
}

class AppointmentsState extends State<Appointments> {
  bool spinnerVisible = false;
  bool messageVisible = false;
  bool srchVisible = false;
  String messageTxt = "";
  String messageType = "";
  String dropDownValue = 'New';
  CollectionReference appointments =
      FirebaseFirestore.instance.collection('appointments');
  final _formKey = GlobalKey<FormState>();
  AppointmentDataModel formData = AppointmentDataModel();
  TextEditingController _nameController = new TextEditingController();
  TextEditingController _phoneController = new TextEditingController();
  TextEditingController _statusController = new TextEditingController();

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    authBloc.dispose();
    super.dispose();
  }

  toggleSpinner() {
    setState(() => spinnerVisible = !spinnerVisible);
  }

  toggleSearch() {
    getData(formData);
    setState(() {
      srchVisible = !srchVisible;
    });
  }

  clearSearch() {
    _nameController.text = "";
    _phoneController.text = "";
    formData.name = null;
    formData.phone = null;
    formData.status = null;
  }

  getData(formData) {
    Query qry = authBloc.appointments;
    if (formData.name != null && formData.name.isNotEmpty) {
      qry = qry.where('name',
          isEqualTo: formData.name); // For example, to be adapted
    }
    if (formData.phone != null && formData.phone.isNotEmpty) {
      qry = qry.where('phone',
          isEqualTo: formData.phone); // For example, to be adapted
    }
    if (formData.status != null && formData.status == "Complete") {
      qry = qry.where('status',
          isEqualTo: "Complete"); // For example, to be adapted
    } else {
      qry = qry.where('status', isEqualTo: "New");
    }
    return qry.limit(10).snapshots();
  }

  showMessage(bool msgVisible, msgType, message) {
    messageVisible = msgVisible;
    setState(() {
      messageType = msgType == "error"
          ? cMessageType.error.toString()
          : cMessageType.success.toString();
      messageTxt = message;
    });
  }

  Future<void> _deleteDoc(String docId) async {
    toggleSpinner();
    messageVisible = true;

    return showDialog<void>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirm'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text(
                    'Are you sure you want to mark this appointment complete? Record #: $docId')
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Confirm'),
              onPressed: () {
                appointments
                    .doc(docId)
                    .update({"status": "Complete"})
                    .then((res) =>
                        {showMessage(true, "success", "Record updated.")})
                    .catchError((error) =>
                        {showMessage(true, "error", error.toString())});
                Navigator.of(context).pop();
                toggleSpinner();
              },
            ),
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
                toggleSpinner();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  // Widget build(BuildContext context) {
  //   AuthBloc authBloc = AuthBloc();
  //   return Material(
  //       child: Container(
  //           margin: EdgeInsets.all(20.0),
  //           child: authBloc.isSignedIn()
  //               ? settings(authBloc)
  //               : loginPage(authBloc)));
  // }

  Widget build(BuildContext context) {
    AuthBloc authBloc = AuthBloc();
    return new Scaffold(
      appBar: AppBar(title: const Text(cAppointment)),
      drawer: Drawer(
          // Add a ListView to the drawer. This ensures the user can scroll
          // through the options in the drawer if there isn't enough vertical
          // space to fit everything.
          // don't need to check if user is Admin or not,
          // this page is only available to admin
          // however, apply rules are firebase database level
          // so that these records are only available to patient
          // or if operator as Admin role
          // child: isAdmin
          //     // ? adminNav(context, authBloc)
          //     ? CustomAdminDrawer()
          //     : CustomGuestDrawer()),
          child: CustomAdminDrawer()),
      body: Center(
        child: Material(
          child: Container(
              margin: EdgeInsets.all(20.0),
              child: authBloc.isSignedIn()
                  ? settings(authBloc)
                  : loginPage(authBloc)),
        ),
      ),
    );
  }

  Widget loginPage(AuthBloc authBloc) {
    return Column(
      children: [
        SizedBox(width: 10, height: 50),
        ElevatedButton(
          child: Text('Click here to go to Login page'),
          onPressed: () {
            Navigator.pushReplacementNamed(
              context,
              '/login',
            );
          },
        )
      ],
    );
  }

  Widget settings(AuthBloc authBloc) {
    return ListView(
      children: [
        Center(
          child: Column(
            children: <Widget>[
              // Container(
              //   margin: EdgeInsets.only(top: 25.0),
              // ),
              // Container(margin: EdgeInsets.all(20.0), child: CustomAdminNav()),
              // : guestNav(context, authBloc)),
              Container(
                margin: EdgeInsets.only(top: 25.0),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.calendar_today_outlined, color: Colors.deepPurple),
                  SizedBox(
                    width: 10,
                    height: 10,
                  ),
                  Text("Appointments", style: cHeaderDarkText),
                  SizedBox(
                    width: 20,
                    height: 20,
                  ),
                  IconButton(
                    icon: Icon(Icons.search, color: Colors.blueAccent),
                    onPressed: () {
                      toggleSearch();
                    },
                  ),
                ],
              ),
              SizedBox(
                width: 10,
                height: 10,
              ),
              Container(
                  width: 400,
                  height: 600,
                  child: !srchVisible
                      ? showAppointments(context, authBloc)
                      : showSearch(context, authBloc)),
              Padding(
                padding: EdgeInsets.symmetric(vertical: 10.0),
              ),
              CustomSpinner(toggleSpinner: spinnerVisible),
              CustomMessage(
                  toggleMessage: messageVisible,
                  toggleMessageType: messageType,
                  toggleMessageTxt: messageTxt),
            ],
          ),
        ),
      ],
    );
  }

  Widget showAppointments(BuildContext context, AuthBloc authBloc) {
    return StreamBuilder<QuerySnapshot>(
        stream: getData(formData),
        // stream: appointments
        //     .limit(10)
        //     .orderBy("appointmentDate", descending: true)
        //     .snapshots(),
        builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.hasError) {
            // return Text('Something went wrong');
            return showMessage(true, "error", "An un-known error has occured.");
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return Text("Loading");
          }

          return new ListView(
            children: snapshot.data.docs.map((DocumentSnapshot document) {
              return new ListTile(
                title: new Text(document.data()['appointmentDate']),
                subtitle: Column(
                  children: [
                    const Divider(
                      color: Colors.black,
                      height: 5,
                      thickness: 2,
                      // indent: 20,
                      // endIndent: 0,
                    ),
                    Row(
                      children: [
                        new Text("Name: "),
                        new Text(document.data()['name']),
                        new Text(" Phone: "),
                        new Text(document.data()['phone']),
                      ],
                    ),
                    Row(
                      children: [
                        Row(
                          children: [
                            new Text(" Comments: "),
                            new Text(document.data()['comments']),
                          ],
                        )
                      ],
                    ),
                    Row(
                      children: [
                        Row(
                          children: [
                            new Text(" Status: "),
                            new Text(document.data()['status'] == null
                                ? "New"
                                : document.data()['status']),
                          ],
                        )
                      ],
                    ),
                    Row(
                      children: [
                        ElevatedButton(
                          child: Text('Vaccine'),
                          onPressed: () {
                            Navigator.pushReplacementNamed(context, '/vaccine',
                                arguments:
                                    ScreenArguments(document.data()['author']));
                          },
                        ),
                        SizedBox(width: 3, height: 50),
                        ElevatedButton(
                          child: Text('OPD/IPD'),
                          onPressed: () {
                            Navigator.pushReplacementNamed(context, '/opd',
                                arguments:
                                    ScreenArguments(document.data()['author']));
                          },
                        ),
                        SizedBox(width: 3, height: 50),
                        IconButton(
                          icon: Icon(Icons.check_box_rounded,
                              color: Colors.green),
                          onPressed: () {
                            _deleteDoc(document.data()['author']);
                          },
                        )
                      ],
                    ),
                    Row(
                      children: [
                        ElevatedButton(
                          child: Text('LAB'),
                          onPressed: () {
                            Navigator.pushReplacementNamed(context, '/lab',
                                arguments:
                                    ScreenArguments(document.data()['author']));
                          },
                        ),
                        SizedBox(width: 3, height: 50),
                        ElevatedButton(
                          child: Text('Rx'),
                          onPressed: () {
                            Navigator.pushReplacementNamed(context, '/rx',
                                arguments:
                                    ScreenArguments(document.data()['author']));
                          },
                        ),
                        SizedBox(width: 3, height: 50),
                        ElevatedButton(
                          child: Text('Message'),
                          onPressed: () {
                            Navigator.pushReplacementNamed(context, '/messages',
                                arguments:
                                    ScreenArguments(document.data()['author']));
                          },
                        ),
                      ],
                    )
                  ],
                ),
              );
            }).toList(),
          );
        });
  }

  Widget showSearch(BuildContext context, AuthBloc authBloc) {
    return ListView(
      children: [
        Center(
          child: Column(
            children: <Widget>[
              Container(
                margin: EdgeInsets.only(top: 25.0),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.search, color: Colors.grey),
                  SizedBox(
                    width: 10,
                    height: 10,
                  ),
                  Text("Search user", style: cHeaderDarkText),
                  SizedBox(
                    width: 30,
                    height: 10,
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: Colors.blueAccent),
                    onPressed: () {
                      toggleSearch();
                    },
                  ),
                ],
              ),
              SizedBox(
                width: 10,
                height: 10,
              ),
              srchForm(authBloc)
            ],
          ),
        ),
      ],
    );
  }

  Widget srchForm(AuthBloc authBloc) {
    return Form(
      key: _formKey,
      autovalidateMode: AutovalidateMode.always,
      // onChanged: () =>
      //     setState(() => _btnEnabled = _formKey.currentState.validate()),
      child: Center(
        child: Column(
          children: <Widget>[
            Container(
              margin: EdgeInsets.only(top: 25.0),
            ),
            Container(
                width: 300.0,
                margin: EdgeInsets.only(top: 25.0),
                child: TextFormField(
                  controller: _nameController,
                  cursorColor: Colors.blueAccent,
                  keyboardType: TextInputType.name,
                  maxLength: 50,
                  obscureText: false,
                  onChanged: (value) => formData.name = value,
                  validator: evalName,
                  decoration: InputDecoration(
                    icon: Icon(Icons.person),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16.0)),
                    hintText: 'your name',
                    labelText: 'Name *',
                    // errorText: snapshot.error,
                  ),
                )),
            Container(
              margin: EdgeInsets.only(top: 5.0),
            ),
            Container(
                width: 300.0,
                margin: EdgeInsets.only(top: 25.0),
                child: TextFormField(
                  controller: _phoneController,
                  cursorColor: Colors.blueAccent,
                  keyboardType: TextInputType.phone,
                  maxLength: 50,
                  obscureText: false,
                  onChanged: (value) => formData.phone = value,
                  validator: evalPhone,
                  decoration: InputDecoration(
                    icon: Icon(Icons.phone),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16.0)),
                    hintText: '123-000-0000',
                    labelText: 'phone *',
                  ),
                )),
            Container(
              width: 100.0,
              margin: EdgeInsets.only(top: 25.0),
              child: DropdownButton<String>(
                value: dropDownValue,
                icon: Icon(Icons.settings),
                iconSize: 24,
                elevation: 16,
                hint: Text("ID Type"),
                style: TextStyle(color: Colors.deepPurple),
                underline: Container(
                  height: 2,
                  color: Colors.deepPurpleAccent,
                ),
                onChanged: (String newValue) {
                  formData.status = newValue;
                  setState(() {
                    dropDownValue = newValue;
                  });
                },
                items: <String>['New', 'Complete']
                    .map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
              ),
            ),
            Container(
              margin: EdgeInsets.only(top: 25.0),
            ),
            Padding(
              padding: EdgeInsets.symmetric(vertical: 10.0),
            ),
            CustomSpinner(toggleSpinner: spinnerVisible),
            CustomMessage(
                toggleMessage: messageVisible,
                toggleMessageType: messageType,
                toggleMessageTxt: messageTxt),
            Container(
              margin: EdgeInsets.only(top: 15.0),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                srchSubmitBtn(context, authBloc),
                SizedBox(
                  width: 30,
                  height: 20,
                ),
                srchClearBtn(context, authBloc),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget srchSubmitBtn(context, authBloc) {
    return ElevatedButton(
      child: Text('search'),
      // onPressed: _btnEnabled == true ? () => toggleSearch() : null,
      onPressed: () => toggleSearch(),
    );
  }

  Widget srchClearBtn(context, authBloc) {
    return ElevatedButton(
      child: Text('clear'),
      // onPressed: _btnEnabled == true ? () => toggleSearch() : null,
      onPressed: () => clearSearch(),
    );
  }
}
