import 'package:flutter/material.dart';
import 'package:otobix/Widgets/empty_page_widget.dart';

class ProcuredPage extends StatelessWidget {
  const ProcuredPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            children: [
              EmptyPageWidget(
                icon: Icons.directions_car,
                title: 'No Procured',
                description: 'You have no procured yet.',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
