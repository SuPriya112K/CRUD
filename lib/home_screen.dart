import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'login_screen.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Controllers for the "Add Student" form
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _rollController = TextEditingController();
  final TextEditingController _programController = TextEditingController();
  final TextEditingController _cgpaController = TextEditingController();

  // Function to handle user sign out
  void _signOut() async {
    await _auth.signOut();
    // Ensure the widget is still mounted before navigating
    if (mounted) {
      Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => LoginScreen()));
    }
  }

  // CREATE: Function to add a new student
  void _addStudent() {
    final user = _auth.currentUser;
    if (user == null) return;

    if (_nameController.text.isEmpty ||
        _rollController.text.isEmpty ||
        _programController.text.isEmpty ||
        _cgpaController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please fill all fields to add a student")),
      );
      return;
    }

    final studentData = {
      'name': _nameController.text.trim(),
      'roll': _rollController.text.trim(),
      'program':_programController.text.trim(),
      'cgpa': int.tryParse(_cgpaController.text.trim()) ?? 0,
    };

    _firestore
        .collection('users')
        .doc(user.uid)
        .collection('students')
        .add(studentData)
        .then((_) {
      _nameController.clear();
      _rollController.clear();
      _programController.clear();
      _cgpaController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Student Added Successfully!")),
      );
      FocusScope.of(context).unfocus();
    }).catchError((error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to add student: $error")),
      );
    });
  }

  // UPDATE: Function to show a dialog for editing a student
  void _showEditDialog(DocumentSnapshot studentDoc) {
    // Controllers for the edit dialog, pre-filled with existing data
    final TextEditingController editNameController =
    TextEditingController(text: studentDoc['name']);
    final TextEditingController editRollController =
    TextEditingController(text: studentDoc['roll']);
    final TextEditingController editProgramController =
    TextEditingController(text: studentDoc['program']);
    final TextEditingController editCgpaController =
    TextEditingController(text: studentDoc['cgpa'].toString());

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Edit Student'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                    controller: editNameController,
                    decoration: InputDecoration(labelText: 'Name')),
                TextField(
                    controller: editRollController,
                    decoration: InputDecoration(labelText: 'Roll no')),
                TextField(
                    controller: editProgramController,
                    decoration: InputDecoration(labelText: 'Study Program')),
                TextField(
                    controller: editCgpaController,
                    decoration: InputDecoration(labelText: 'CGPA'),
                    keyboardType: TextInputType.number),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final updatedData = {
                  'name': editNameController.text.trim(),
                  'roll': editRollController.text.trim(),
                  'program': editProgramController.text.trim(),
                  'cgpa': int.tryParse(editCgpaController.text.trim()) ?? 0,
                };
                // Update the document in Firestore
                studentDoc.reference.update(updatedData);
                Navigator.of(context).pop();
              },
              child: Text('Update'),
            ),
          ],
        );
      },
    );
  }

  // DELETE: Function to delete a student
  void _deleteStudent(String studentId) {
    final user = _auth.currentUser;
    if (user == null) return;
    _firestore
        .collection('users')
        .doc(user.uid)
        .collection('students')
        .doc(studentId)
        .delete();
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Student App",
          style: TextStyle(
            fontSize: 40,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.yellowAccent,
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: _signOut,
          ),
        ],
      ),
      body: user == null
          ? Center(child: Text("Not logged in"))
          : Column(
        children: [
          // CREATE UI
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [

                SizedBox(height: 10),
                TextField(
                    controller: _nameController,
                    decoration: InputDecoration(
                        labelText: 'Name', border: OutlineInputBorder())),
                SizedBox(height: 8),
                TextField(
                    controller: _rollController,
                    decoration: InputDecoration(
                        labelText: 'Roll no',
                        border: OutlineInputBorder())),
                SizedBox(height: 8),
                TextField(
                    controller: _programController,
                    decoration: InputDecoration(
                        labelText: 'Study Program',
                        border: OutlineInputBorder())),
                SizedBox(height: 8),
                TextField(
                    controller: _cgpaController,
                    decoration: InputDecoration(
                        labelText: 'CGPA', border: OutlineInputBorder()),
                    keyboardType: TextInputType.number),
                SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _addStudent,
                  child: Text('Create Student'),
                ),

              ],
            ),
          ),
          Divider(thickness: 1),
          // READ (VIEW) UI
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2.0),
            child: Text(
              'Student List',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('users')
                  .doc(user.uid)
                  .collection('students')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                      child: Text("No students found. Add one!"));
                }
                final students = snapshot.data!.docs;
                // Use SingleChildScrollView to make the DataTable horizontally scrollable
                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columns: const <DataColumn>[
                      DataColumn(label: Text('Name')),
                      DataColumn(label: Text('Roll No')),
                      DataColumn(label: Text('Study Program')),
                      DataColumn(label: Text('CGPA')),
                      DataColumn(label: Text('Actions')),
                    ],
                    rows: students.map((student) {
                      return DataRow(cells: [
                        DataCell(Text(student['name'])),
                        DataCell(Text(student['roll'])),
                        DataCell(Text(student['program'])),
                        DataCell(Text(student['cgpa'].toString())),
                        DataCell(
                          Row(
                            children: [
                              IconButton(
                                icon: Icon(Icons.edit, color: Colors.blue),
                                onPressed: () => _showEditDialog(student),
                              ),
                              IconButton(
                                icon: Icon(Icons.delete, color: Colors.red),
                                onPressed: () => _deleteStudent(student.id),
                              ),
                            ],
                          ),
                        ),
                      ]);
                    }).toList(),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
