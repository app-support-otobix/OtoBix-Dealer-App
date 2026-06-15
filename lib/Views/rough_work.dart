import 'package:flutter/material.dart';
import 'package:otobix/Utils/app_colors.dart';
import 'package:otobix/Widgets/accordion_widget.dart';

class RoughWorkPage extends StatelessWidget {
  const RoughWorkPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Rough Work Page',
          style: TextStyle(color: AppColors.white),
        ),
        centerTitle: true,
        backgroundColor: AppColors.green,
        elevation: 10,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Column(
            children: [
              AccordionWidget(
                title: 'Accordion 1',
                content: Column(
                  children: [
                    Text('Content 1'),
                    Text('Content 1'),
                    Text('Content 1'),
                  ],
                ),
              ),
              const SizedBox(height: 15),
              AccordionWidget(
                title: 'Accordion 2',
                content: const Text('Content 2'),
              ),
              const SizedBox(height: 15),
              AccordionWidget(
                title: 'Accordion 3',
                content: const Text('Content 3'),
              ),
              const SizedBox(height: 15),
              AccordionWidget(
                title: 'Accordion 3',
                content: const Text('Content 3'),
              ),
              const SizedBox(height: 15),
              AccordionWidget(
                title: 'Accordion 3',
                content: const Text('Content 3'),
              ),
              const SizedBox(height: 15),
              AccordionWidget(
                title: 'Accordion 3',
                content: const Text('Content 3'),
              ),
              const SizedBox(height: 15),
              AccordionWidget(
                title: 'Accordion 3',
                content: const Text('Content 3'),
              ),
              const SizedBox(height: 15),
              AccordionWidget(
                title: 'Accordion 3',
                content: const Text('Content 3'),
              ),
              const SizedBox(height: 15),
              AccordionWidget(
                title: 'Accordion 3',
                content: const Text('Content 3'),
              ),
              const SizedBox(height: 15),
              AccordionWidget(
                title: 'Accordion 3',
                content: const Text('Content 3'),
              ),
              const SizedBox(height: 15),
              AccordionWidget(
                title: 'Accordion 3',
                content: const Text('Content 3'),
              ),
              const SizedBox(height: 15),
              AccordionWidget(
                title: 'Accordion 3',
                content: const Text('Content 3'),
              ),
              const SizedBox(height: 15),
              AccordionWidget(
                title: 'Accordion 3',
                content: const Text('Content 3'),
              ),
              const SizedBox(height: 15),
              AccordionWidget(
                title: 'Accordion 3',
                content: const Text('Content 3'),
              ),
              const SizedBox(height: 15),
              AccordionWidget(
                title: 'Accordion 3',
                content: const Text('Content 3'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
