import 'package:flutter/material.dart';
import 'package:otobix/Widgets/empty_page_widget.dart';

class RCTransferPage extends StatelessWidget {
  const RCTransferPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            children: [
              EmptyPageWidget(
                icon: Icons.swap_horiz_outlined,
                title: 'No RC Transfer',
                description: 'You have no rc transfers yet.',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
