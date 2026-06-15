import 'package:flutter/material.dart';
import 'package:otobix/Widgets/empty_page_widget.dart';

class InNegotiationPage extends StatelessWidget {
  const InNegotiationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            children: [
              EmptyPageWidget(
                icon: Icons.forum,
                title: 'No Negotiations',
                description: 'You have no negotiations yet.',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
