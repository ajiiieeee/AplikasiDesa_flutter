import 'package:digitalv/widgets/bottom_navbar.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:flutter_svg/flutter_svg.dart';
import '../shared/shared.dart';
import 'dart:math';
import '../config/globals.dart';
import '../auth/LupaPassword.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:digitalv/widgets/snackbarcustom.dart';

class Loginregis extends StatefulWidget {
  const Loginregis({super.key});

  @override
  _LoginregisState createState() => _LoginregisState();
}

class _LoginregisState extends State<Loginregis> {
  bool isVisible = false;
  bool isPasswordVisible = false;
  final _formKey = GlobalKey<FormState>();
  final _loginFormKey = GlobalKey<FormState>(); // Tambahkan ini
  final _nikController = TextEditingController();
  final _passwordController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final nikLoginController = TextEditingController();
  final loginPasswordController = TextEditingController();

  Future<void> simpanStatusLogin(String token) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);
  }

  // Backend registrasi
  Future<void> _register() async {
    final String nik = _nikController.text.trim();
    final String password = _passwordController.text.trim();
    final String email = _emailController.text.trim();
    final String phone = _phoneController.text.trim();

    if (nik.isEmpty || password.isEmpty || email.isEmpty || phone.isEmpty) {
      showCustomSnackbarAtTop(
        context: context,
        message: 'Semua field harus diisi',
        backgroundColor: Colors.red,
        icon: Icons.error,
      );
      return;
    }

    try {
      final response = await http.post(
        Uri.parse('$baseURL/register'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, String>{
          'nik': nik,
          'password': password,
          'email': email,
          'no_hp': phone,
        }),
      );

      final responseData = jsonDecode(response.body);

      print('Status Code: ${response.statusCode}');
      print('Response Body: ${response.body}');

      if (response.statusCode == 201) {
        showCustomSnackbar(
          context: context,
          message: responseData['message'] ?? 'Akun berhasil diaktivasi.',
          backgroundColor: Colors.green,
          icon: Icons.check_circle,
        );
        _nikController.clear();
        _passwordController.clear();
        _emailController.clear();
        _phoneController.clear();


        Navigator.pop(context);
      } else {
        // Menampilkan pesan error dari response
       String errorMessage = responseData['message'] ?? 'Terjadi kesalahan';

        // Coba ambil error validasi detail
        if (responseData['errors'] != null) {
          final errors = responseData['errors'] as Map<String, dynamic>;
          final firstKey = errors.keys.first;
          final firstErrorList = errors[firstKey];

          if (firstErrorList is List && firstErrorList.isNotEmpty) {
            errorMessage = firstErrorList.first;
          }
        }

        showCustomSnackbarAtTop(
          context: context,
          message: '$errorMessage',
          backgroundColor: Colors.red,
          icon: Icons.error,
        );
      }
    } on SocketException {
      showCustomSnackbarAtTop(
        context: context,
        message: 'Tidak ada koneksi internet',
        backgroundColor: Colors.orange,
        icon: Icons.wifi_off,
      );
    } on TimeoutException {
      showCustomSnackbarAtTop(
        context: context,
        message: 'Koneksi timeout, coba lagi!',
        backgroundColor: Colors.orange,
        icon: Icons.timer_off,
      );
    } catch (e) {
      showCustomSnackbarAtTop(
        context: context,
        message: 'Terjadi kesalahan: $e',
        backgroundColor: Colors.red,
        icon: Icons.error,
      );
    }
  }

 Future<void> login(BuildContext context) async {
    final String nikLogin = nikLoginController.text.trim();
    final String passwordLogin = loginPasswordController.text.trim();

    if (nikLogin.isEmpty || passwordLogin.isEmpty) {
      showCustomSnackbarAtTop(
        context: context,
        message: 'NIK dan Password harus diisi',
        backgroundColor: Colors.red,
        icon: Icons.error,
      );
      return;
    }

    try {
      final response = await http.post(
        Uri.parse('$baseURL/login'),
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: jsonEncode({'nik': nikLogin, 'password': passwordLogin}),
      );

      final responseData = jsonDecode(response.body);

      //  Cetak response status dan body untuk debugging
      print('📥 Status Code: ${response.statusCode}');
      print('📦 Response Body: ${response.body}');

      if (response.statusCode == 200 &&
          responseData['status'] == 'success' &&
          responseData['data'] != null) {
        final data = responseData['data'];

        final String namaPengguna = data['nama'] ?? 'Pengguna';
        final String nikPengguna = data['nik'] ?? '';
        final String? token = data['token'];
        final String roleName = data['role_name'] ?? 'warga';
        final int level = (data['level'] as num?)?.toInt() ?? 5;

        await _saveUserData(namaPengguna, nikPengguna);
        await _saveRoleData(roleName, level);

        if (token != null) {
          await simpanStatusLogin(token);
          print('🔐 TOKEN YANG DISIMPAN: $token');
          print('👤 ROLE: $roleName (level $level)');
        }

        showCustomSnackbar(
          context: context,
          message: 'Selamat Datang, $namaPengguna!',
          backgroundColor: Colors.green,
          icon: Icons.check_circle,
        );

        await Future.delayed(const Duration(milliseconds: 500));

        if (!context.mounted) return;

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => BottomNavBar(role: roleName),
          ),
        );
      } else if ([401, 403, 404].contains(response.statusCode)) {
        final errorMessage = responseData['message'] ?? 'Login gagal.';
        showCustomSnackbarAtTop(
          context: context,
          message: errorMessage,
          backgroundColor: Colors.red,
          icon: Icons.error,
        );
      } else {
        showCustomSnackbarAtTop(
          context: context,
          message:
              'Terjadi kesalahan: ${responseData['message'] ?? 'Unknown error'}',
          backgroundColor: Colors.red,
          icon: Icons.error,
        );
      }
    } on SocketException {
      showCustomSnackbarAtTop(
        context: context,
        message: 'Tidak ada koneksi internet',
        backgroundColor: Colors.orange,
        icon: Icons.wifi_off,
      );
    } on TimeoutException {
      showCustomSnackbarAtTop(
        context: context,
        message: 'Koneksi timeout, coba lagi!',
        backgroundColor: Colors.orange,
        icon: Icons.timer_off,
      );
    } catch (e, stackTrace) {
     print('❗ ERROR: $e');
    print('🧾 STACKTRACE: $stackTrace');
    showCustomSnackbarAtTop(
      context: context,
    message: 'Terjadi kesalahan tak terduga: $e',
    backgroundColor: Colors.red,
    icon: Icons.error,
  );
}
    
  }


  Future<void> _saveUserData(String nama, String nik) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('nama', nama);
    await prefs.setString('nik', nik);
  }

  Future<void> _saveRoleData(String roleName, int level) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('role_name', roleName);
    await prefs.setInt('level', level);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Gambar background yang mengisi seluruh layar
          Positioned.fill(
            child: SvgPicture.asset(
              'assets/images/FIRST PAGE.svg',
              fit: BoxFit.cover,
            ),
          ),

          // Konten yang akan ditampilkan di atas gambar background
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/images/boy2.png',
                    width: MediaQuery.of(context).size.width - 40,
                  ),
                  const SizedBox(height: 20), // Jarak antara gambar dan teks

                  SizedBox(
                    width: 215, // samain dengan tombol aktivasi
                    child: Text(
                      "Pertama kali menggunakan aplikasi?",
                      style: GoogleFonts.poppins(
                         color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                      ),
                      textAlign: TextAlign.left,
                    ),
                  ),
                  const SizedBox(height: 5),

                  // Tombol aktivasi
                  SizedBox(
                    height: 39,
                    // width: MediaQuery.of(context).size.width - 40,
                    width: 215,

                    child: ElevatedButton(
                      onPressed: () {
                        showRegisterModal(context);
                      },

                      child: Text(
                        'Aktivasi Akun',
                        style: GoogleFonts.poppins(
                           color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        // backgroundColor: const Color.fromARGB(255, 212, 209, 181),
                        backgroundColor: primaryColor,

                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // text
                  SizedBox(
                    width:
                        215, //agar posisi sama dengan login (mulai dari kiri sehingga sejajar)
                    child: Text(
                      "Sudah aktivasi akun?",
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                      textAlign: TextAlign.left,
                    ),
                  ),
                  const SizedBox(height: 5),

                  // Tombol Login
                  SizedBox(
                    height: 39,
                    width: 215,

                    // width: 215,
                    child: ElevatedButton(
                      onPressed: () {
                        showLoginModal(context);
                      },
                      child: Text(
                        'Login',
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0057A6),
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        // backgroundColor: const Color.fromARGB(255, 78, 163, 232),
                        backgroundColor: whiteColor,
                        shape: RoundedRectangleBorder(
                          side: BorderSide(color: primaryColor, width: 3),
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Modal aktivasi
  // Modal aktivasi
  void showRegisterModal(BuildContext context) {
    showModalBottomSheet(
      isScrollControlled: true,
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        bool modalRegisterPasswordVisible = false;

        return StatefulBuilder(
          builder: (context, setModalState) {
            return DraggableScrollableSheet(
              expand: false,
              initialChildSize: 0.6,
              minChildSize: 0.4,
              maxChildSize: 0.9,
              builder: (context, scrollController) {
                return Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(40),
                      topRight: Radius.circular(40),
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 25,
                  ),
                  child: SingleChildScrollView(
                    controller: scrollController,
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Center(
                            child: Container(
                              width: 50,
                              height: 5,
                              margin: const EdgeInsets.only(bottom: 15),
                              decoration: BoxDecoration(
                                color: Colors.grey[300],
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),

                          const Text(
                            "Aktivasi akun",
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Poppins',
                            ),
                            textAlign: TextAlign.center,
                          ),

                          const SizedBox(height: 25),

                          // NIK
                          TextFormField(
                            controller: _nikController,
                            decoration: const InputDecoration(
                              icon: Icon(Icons.person),
                              labelText: 'NIK',
                              hintText: 'Masukkan NIK Anda',
                              border: OutlineInputBorder(),
                            ),
                            style: const TextStyle(fontSize: 14),
                          ),

                          const SizedBox(height: 20),

                          // Email
                          TextFormField(
                            controller: _emailController,
                            decoration: const InputDecoration(
                              icon: Icon(Icons.email),
                              labelText: 'E-Mail',
                              hintText: 'Masukkan E-Mail Anda',
                              border: OutlineInputBorder(),
                            ),
                            style: const TextStyle(fontSize: 14),
                          ),

                          const SizedBox(height: 20),

                          // Nomor HP
                          TextFormField(
                            controller: _phoneController,
                            decoration: const InputDecoration(
                              icon: Icon(Icons.phone),
                              labelText: 'Nomor HP',
                              hintText: 'Masukkan Nomor HP Anda',
                              border: OutlineInputBorder(),
                            ),
                            style: const TextStyle(fontSize: 14),
                          ),

                          const SizedBox(height: 20),

                          // Password
                          TextFormField(
                            controller: _passwordController,
                            obscureText: !modalRegisterPasswordVisible,
                            decoration: InputDecoration(
                              icon: const Icon(Icons.lock),
                              suffixIcon: IconButton(
                                onPressed: () {
                                  setModalState(() {
                                    modalRegisterPasswordVisible =
                                        !modalRegisterPasswordVisible;
                                  });
                                },
                                icon: Icon(
                                  modalRegisterPasswordVisible
                                      ? Icons.visibility
                                      : Icons.visibility_off,
                                ),
                              ),
                              labelText: 'Password',
                              hintText: 'Masukkan Password Anda',
                              border: const OutlineInputBorder(),
                            ),
                            style: const TextStyle(fontSize: 14),
                          ),

                          const SizedBox(height: 20),

                          // Tombol Aktivasi
                          Container(
                            margin: const EdgeInsets.only(left: 40),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(
                                  height: 50,
                                  width: 440,
                                  child: ElevatedButton(
                                    onPressed: () {
                                      if (_formKey.currentState!.validate()) {
                                        _register();
                                      }
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: primaryColor,
                                      shape: RoundedRectangleBorder(
                                        side: const BorderSide(
                                          color: Color(0xFF0057A6),
                                          width: 3,
                                        ),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                    child: Text(
                                      'Aktivasi',
                                      style: GoogleFonts.poppins(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),

                                const SizedBox(height: 20),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
  // Modal untuk Login
  void showLoginModal(BuildContext context) {
    showModalBottomSheet(
      isScrollControlled: true,
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        bool modalPasswordVisible = false;

        return StatefulBuilder(
          builder: (context, setModalState) {
            return DraggableScrollableSheet(
              expand: false,
              initialChildSize: 0.5,
              minChildSize: 0.4,
              maxChildSize: 0.9,
              builder: (context, scrollController) {
                return Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(40),
                      topRight: Radius.circular(40),
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 25,
                  ),
                  child: SingleChildScrollView(
                    controller: scrollController,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Container(
                            width: 50,
                            height: 5,
                            margin: const EdgeInsets.only(bottom: 15),
                            decoration: BoxDecoration(
                              color: Colors.grey[300],
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                        Text(
                          "Login",
                          style: GoogleFonts.poppins(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 20),

                        TextFormField(
                          controller: nikLoginController,
                          decoration: const InputDecoration(
                            icon: Icon(Icons.person),
                            labelText: 'NIK',
                            border: OutlineInputBorder(),
                          ),
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 20),

                        TextFormField(
                          controller: loginPasswordController,
                          obscureText: !modalPasswordVisible,
                          decoration: InputDecoration(
                            icon: const Icon(Icons.lock),
                            suffixIcon: IconButton(
                              onPressed: () {
                                setModalState(() {
                                  modalPasswordVisible = !modalPasswordVisible;
                                });
                              },
                              icon: Icon(
                                modalPasswordVisible
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                              ),
                            ),
                            labelText: 'Password',
                            border: const OutlineInputBorder(),
                          ),
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),

                        const SizedBox(height: 10),

                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const LupaPassword(),
                                ),
                              );
                            },
                            child: Text(
                              'Lupa Password?',
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                color: Colors.blue,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 10),

                        Container(
                          margin: const EdgeInsets.only(left: 40),
                          child: SizedBox(
                            height: 50,
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () {
                                login(context);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryColor,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: Text(
                                'LOGIN',
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 20,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}
