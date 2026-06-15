import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:otobix/Controllers/account_controller.dart';
import 'package:otobix/Utils/app_colors.dart';
import 'package:otobix/Utils/app_constants.dart';

class EditProfileScreen extends StatelessWidget {
  EditProfileScreen({super.key});

  final _formKey = GlobalKey<FormState>();
  final controller = Get.put(AccountController());

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.isLoading.value) {
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      }
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          // leading: IconButton(
          //   icon: const Icon(Icons.arrow_back, color: Colors.black),
          //   onPressed: () {
          //     Get.back();
          //   },
          // ),
          elevation: 0,
          // backgroundColor: AppColors.green,
          iconTheme: const IconThemeData(color: AppColors.green),
          // automaticallyImplyLeading: false,
          title: const Text(
            'Edit My Profile',
            style: TextStyle(
              color: Colors.green,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                controller.updateProfile();
              },
              child: const Text(
                'Save',
                style: TextStyle(color: Colors.redAccent, fontSize: 16),
              ),
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    Obx(() {
                      final imageUrl = controller.imageUrl.value;
                      final imageFile = controller.imageFile.value;

                      return CircleAvatar(
                        radius: 55,
                        backgroundImage:
                            imageFile != null
                                ? FileImage(imageFile) as ImageProvider
                                : (imageUrl.isNotEmpty
                                    ? NetworkImage(
                                      imageUrl.startsWith('http')
                                          ? imageUrl
                                          : imageUrl,
                                    )
                                    : null),
                        child:
                            imageFile == null && imageUrl.isEmpty
                                ? const Icon(Icons.person, size: 55)
                                : null,
                      );
                    }),

                    Positioned(
                      bottom: 0,
                      right: 4,
                      child: InkWell(
                        onTap: () {
                          controller.pickImageFromDevice();
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                            border: Border.all(color: Colors.redAccent),
                          ),
                          child: const Icon(
                            Icons.add,
                            color: Colors.redAccent,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // _buildTextField('Name', controller.userName),
                _buildTextField('Email', controller.userEmail),
                // _buildTextField('Phone Number', controller.phoneNumber),
                _buildTextField('Location', controller.location),

                if (controller.userRole.value == 'Dealer') ...[
                  _buildTextField('Dealership Name', controller.dealershipName),
                  // _buildTextField('Entity Type', controller.entityType),
                  _buildTextField(
                    'Primary Contact Person',
                    controller.primaryContactPerson,
                  ),
                  _buildTextField(
                    'Primary Contact Number',
                    controller.primaryContactNumber,
                  ),
                  _buildTextField(
                    'Secondary Contact Person',
                    controller.secondaryContactPerson,
                  ),
                  _buildTextField(
                    'Secondary Contact Number',
                    controller.secondaryContactNumber,
                  ),
                ],

                if ([
                  AppConstants.roles.dealer,
                  AppConstants.roles.customer,
                  AppConstants.roles.salesManager,
                ].contains(controller.userRole.value))
                  _buildAddressList(controller),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      );
    });
  }

  Widget _buildTextField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: AppColors.blue,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 6),
          TextFormField(
            controller: controller,
            style: const TextStyle(fontSize: 14),
            decoration: InputDecoration(
              enabled: false,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.blue),
              ),
              fillColor: Colors.grey.shade100,
              filled: true,
            ),
            validator:
                (value) => value == null || value.isEmpty ? 'Required' : null,
          ),
        ],
      ),
    );
  }

  Widget _buildAddressList(AccountController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Text(
          'Addresses',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: AppColors.blue,
          ),
        ),
        ...controller.addressList.map(
          (addr) => _buildTextField(
            'Address ${controller.addressList.indexOf(addr) + 1}',
            TextEditingController(text: addr)..addListener(() {
              controller.addressList[controller.addressList.indexOf(addr)] =
                  addr;
            }),
          ),
        ),
      ],
    );
  }
}
