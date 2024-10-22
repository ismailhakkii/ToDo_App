import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';

class PersonalPage extends StatefulWidget {
  @override
  _PersonalPageState createState() => _PersonalPageState();
}

class _PersonalPageState extends State<PersonalPage> {
  final _formKey = GlobalKey<FormState>();
  String? _name = '';
  String? _gender;
  DateTime? _birthDate;
  File? _image;

  // Ad Soyad için TextEditingController
  late TextEditingController _nameController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(); // Controller'ı başlatıyoruz
    _loadPersonalInfo();
  }

  @override
  void dispose() {
    _nameController.dispose(); // Bellek sızıntılarını önlemek için controller'ı dispose ediyoruz
    super.dispose();
  }

  // Kişisel bilgileri yükleme fonksiyonu
  void _loadPersonalInfo() async {
    final prefs = await SharedPreferences.getInstance();

    String? name = prefs.getString('name') ?? '';
    String? gender = prefs.getString('gender');
    String? birthDateString = prefs.getString('birthDate');

    DateTime? birthDate;
    if (birthDateString != null) {
      try {
        birthDate = DateTime.parse(birthDateString);
      } catch (e) {
        birthDate = null;
        print('Doğum tarihi parse edilemedi: $e');
      }
    }

    // Ekran güncellemesi için setState kullanıyoruz
    setState(() {
      _name = name;
      _gender = gender;
      _birthDate = birthDate;
      _nameController.text = _name ?? '';
    });

    _loadProfileImage();
  }

  // Profil fotoğrafını yükleme fonksiyonu
  void _loadProfileImage() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final path = '${directory.path}/profile_image.png';
      final file = File(path);
      if (await file.exists()) {
        setState(() {
          _image = file;
        });
      }
    } catch (e) {
      print('Profil fotoğrafı yüklenirken hata oluştu: $e');
    }
  }

  // Profil fotoğrafı seçme fonksiyonu
  Future<void> _pickImage() async {
    try {
      final pickedFile =
          await ImagePicker().pickImage(source: ImageSource.gallery);

      if (pickedFile != null) {
        setState(() {
          _image = File(pickedFile.path);
        });
        _saveProfileImage();
      }
    } catch (e) {
      print('Resim seçerken hata oluştu: $e');
    }
  }

  // Profil fotoğrafını kaydetme fonksiyonu
  void _saveProfileImage() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final path = '${directory.path}/profile_image.png';
      await _image?.copy(path);
    } catch (e) {
      print('Profil fotoğrafı kaydedilirken hata oluştu: $e');
    }
  }

  // Doğum tarihi seçme fonksiyonu
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _birthDate ?? DateTime(2000),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      locale: const Locale('tr', ''),
    );
    if (picked != null && picked != _birthDate) {
      setState(() {
        _birthDate = picked;
      });
    }
  }

  // Formu kaydetme fonksiyonu
  void _saveForm() async {
    if (_formKey.currentState != null && _formKey.currentState!.validate()) {
      // _formKey.currentState!.save(); // Gerekli değil çünkü TextEditingController kullanıyoruz
      final prefs = await SharedPreferences.getInstance();
      prefs.setString('name', _nameController.text.trim());
      prefs.setString('gender', _gender ?? '');
      if (_birthDate != null) {
        prefs.setString('birthDate', _birthDate!.toIso8601String());
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Bilgiler kaydedildi')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final genders = ['Erkek', 'Kadın', 'Diğer'];
    return Scaffold(
      appBar: AppBar(
        title: Text('Kişisel Bilgiler'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                // Profil Fotoğrafı
                GestureDetector(
                  onTap: _pickImage,
                  child: CircleAvatar(
                    radius: 50,
                    backgroundImage: _image != null
                        ? FileImage(_image!)
                        : AssetImage('assets/placeholder.png')
                            as ImageProvider<Object>,
                  ),
                ),
                SizedBox(height: 20),
                // Ad Soyad
                TextFormField(
                  controller: _nameController, // Controller kullanıyoruz
                  decoration: InputDecoration(labelText: 'Ad Soyad'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Lütfen adınızı giriniz';
                    }
                    return null;
                  },
                  onChanged: (value) {
                    _name = value;
                  },
                ),
                SizedBox(height: 10),
                // Cinsiyet
                DropdownButtonFormField<String>(
                  value: _gender,
                  decoration: InputDecoration(labelText: 'Cinsiyet'),
                  items: genders
                      .map((gender) => DropdownMenuItem(
                            child: Text(gender),
                            value: gender,
                          ))
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      _gender = value;
                    });
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Lütfen cinsiyetinizi seçiniz';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 10),
                // Doğum Tarihi
                ListTile(
                  title: Text(_birthDate == null
                      ? 'Doğum Tarihi Seçiniz'
                      : 'Doğum Tarihi: ${_birthDate!.day}/${_birthDate!.month}/${_birthDate!.year}'),
                  trailing: Icon(Icons.calendar_today),
                  onTap: () => _selectDate(context),
                ),
                SizedBox(height: 20),
                // Kaydet Butonu
                ElevatedButton(
                  onPressed: _saveForm,
                  child: Text('Kaydet'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
