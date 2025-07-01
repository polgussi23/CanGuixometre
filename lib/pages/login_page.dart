import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../services/user_provider.dart';

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _login() async {
    setState(() => _isLoading = true);
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    try {
      final response = await ApiService.login(email, password);
      if (response != null && response['token'] != null) {
        final userProvider = context.read<UserProvider>();
        await userProvider.saveUser(
          response['user']['nom'],
          response['user']['usuari'],
          response['user']['id'],
          response['token'],
        );
        Navigator.pushReplacementNamed(context, '/home');
      } else {
        setState(() => _errorMessage = 'Credencials incorrectes');
      }
    } catch (e) {
      setState(() => _errorMessage = 'Error de connexió');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showTrustDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Contrasenya?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'En aquesta app, confiem plenament els uns en els altres. No hi ha contrasenyes ni verificacions, '
              'només germanor i respecte. Aquí, tothom és benvingut!',
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16.0),
            Image.asset('assets/images/trust.png', height: 100), // Assegura’t de tenir la imatge a la carpeta assets
          ],
        ),
        actions: [
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: Colors.black, backgroundColor: Colors.yellow,
            ),
            onPressed: () => Navigator.of(context).pop(),
            child: Text('D\'acord'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _emailController,
              decoration: InputDecoration(labelText: 'Usuari'),
              keyboardType: TextInputType.emailAddress,
            ),
            SizedBox(height: 16.0),
            GestureDetector(
              onTap: _showTrustDialog,
              child: AbsorbPointer(
                child: TextField(
                  controller: _passwordController,
                  decoration: InputDecoration(labelText: 'Contrasenya'),
                  obscureText: true,
                ),
              ),
            ),
            if (_errorMessage != null) ...[
              SizedBox(height: 16.0),
              Text(
                _errorMessage!,
                style: TextStyle(color: Colors.red),
              ),
            ],
            SizedBox(height: 32.0),
            _isLoading
                ? CircularProgressIndicator()
                : ElevatedButton(
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.black, backgroundColor: Colors.yellow,
                    ),
                    onPressed: _login,
                    child: Text('Entra'),
                  ),
          ],
        ),
      ),
    );
  }
}
