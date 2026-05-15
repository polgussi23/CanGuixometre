import 'package:can_guix/pages/jocs/busca_alls_page.dart';
import 'package:can_guix/pages/jocs/pesca_fregits_page.dart';
import 'package:can_guix/pages/jocs/salt_calcot_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

class JocsPage extends StatelessWidget {
  final screenWidth = 0;

  double calculWidthImatges(BuildContext context) {
    double screenWidth = MediaQuery.sizeOf(context).width;
    double imatgesWidth = screenWidth / 2.5;
    return imatgesWidth;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Zona de Jocs")),
      body: SingleChildScrollView(
        child: Center(
          child: Column(
            spacing: 50,
            children: [
              SizedBox(),
              GestureDetector(
                  onTap: () {
                    Navigator.push(context,
                        MaterialPageRoute(builder: (context) => BuscaAllsPage()));
                  },
                  child: Image.asset('assets/images/jocs/buscaAlls/buscaAlls.png',
                      width: calculWidthImatges(context))),
              GestureDetector(
                  onTap: () {
                    Navigator.push(context,
                        MaterialPageRoute(builder: (context) => PescaFregitsPage()));
                  },
                  child: Image.asset('assets/images/jocs/pescaFregitsLogo.png',
                      width: calculWidthImatges(context))),
              GestureDetector(
                  onTap: () {
                    Navigator.push(context,
                        MaterialPageRoute(builder: (context) => SaltCalcotPage()));
                  },
                  child: Image.asset('assets/images/jocs/saltCalcot/saltCalcotLogo.png',
                      width: calculWidthImatges(context))),
            ],
          ),
        ),
      ),
    );
  }
}
