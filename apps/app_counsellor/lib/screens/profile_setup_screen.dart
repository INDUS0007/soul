import 'package:flutter/material.dart';
import 'package:common/widgets/widgets.dart';
import '../models/counselor.dart';

class ProfileSetupScreen extends StatefulWidget {
  final Counselor counselor;

  const ProfileSetupScreen({super.key, required this.counselor});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _bioController;
  late TextEditingController _specializationController;
  List<String> _certifications = [];

  @override
  void initState() {
    super.initState();
    _bioController = TextEditingController(text: widget.counselor.bio);
    _specializationController = TextEditingController(
      text: widget.counselor.specialization,
    );
    _certifications = List.from(widget.counselor.certifications);
  }

  @override
  void dispose() {
    _bioController.dispose();
    _specializationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile Setup'),
        actions: [
          TextButton(
            onPressed: _saveProfile,
            child: const Text(
              'Save',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profile Photo Section
              Center(
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 60,
                      backgroundColor: Theme.of(
                        context,
                      ).colorScheme.primaryContainer,
                      child: widget.counselor.photoUrl != null
                          ? ClipOval(
                              child: Image.network(
                                widget.counselor.photoUrl!,
                                width: 120,
                                height: 120,
                                fit: BoxFit.cover,
                              ),
                            )
                          : Text(
                              widget.counselor.name.substring(0, 1),
                              style: const TextStyle(fontSize: 48),
                            ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: CircleAvatar(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        child: IconButton(
                          icon: const Icon(
                            Icons.camera_alt,
                            color: Colors.white,
                            size: 20,
                          ),
                          onPressed: _uploadPhoto,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Basic Information
              Text(
                'Basic Information',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              TextFormField(
                initialValue: widget.counselor.name,
                decoration: const InputDecoration(
                  labelText: 'Full Name',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person_outline),
                ),
                validator: (value) =>
                    value?.isEmpty ?? true ? 'Name is required' : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                initialValue: widget.counselor.email,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email_outlined),
                ),
                enabled: false,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _specializationController,
                decoration: const InputDecoration(
                  labelText: 'Specialization',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.medical_services_outlined),
                  hintText: 'e.g., Anxiety & Depression',
                ),
                validator: (value) => value?.isEmpty ?? true
                    ? 'Specialization is required'
                    : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _bioController,
                decoration: const InputDecoration(
                  labelText: 'Bio',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.description_outlined),
                  hintText: 'Tell clients about yourself',
                ),
                maxLines: 4,
                validator: (value) =>
                    value?.isEmpty ?? true ? 'Bio is required' : null,
              ),
              const SizedBox(height: 32),

              // Certifications
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Certifications & Licenses',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline),
                    onPressed: _addCertification,
                  ),
                ],
              ),
              const SizedBox(height: 16),

              if (_certifications.isEmpty)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        Icon(
                          Icons.workspace_premium_outlined,
                          size: 48,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'No certifications added yet',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                )
              else
                ..._certifications.map(
                  (cert) => Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: const Icon(
                        Icons.verified_outlined,
                        color: Colors.green,
                      ),
                      title: Text(cert),
                      trailing: IconButton(
                        icon: const Icon(
                          Icons.delete_outline,
                          color: Colors.red,
                        ),
                        onPressed: () {
                          setState(() {
                            _certifications.remove(cert);
                          });
                        },
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 16),

              ElevatedButton.icon(
                onPressed: _uploadDocuments,
                icon: const Icon(Icons.upload_file),
                label: const Text('Upload License Documents'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                ),
              ),
              const SizedBox(height: 32),

              // Account Status
              Text(
                'Account Status',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _buildStatusRow(
                        'Profile Completion',
                        widget.counselor.bio != null &&
                            widget.counselor.certifications.isNotEmpty,
                      ),
                      const Divider(),
                      _buildStatusRow('Email Verified', true),
                      const Divider(),
                      _buildStatusRow(
                        'License Verified',
                        widget.counselor.isVerified,
                      ),
                      const Divider(),
                      _buildStatusRow(
                        'Availability Set',
                        true, // Check actual availability
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusRow(String label, bool isComplete) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 16)),
        Row(
          children: [
            Icon(
              isComplete ? Icons.check_circle : Icons.radio_button_unchecked,
              color: isComplete ? Colors.green : Colors.grey,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              isComplete ? 'Complete' : 'Pending',
              style: TextStyle(
                color: isComplete ? Colors.green : Colors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _uploadPhoto() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Upload Photo'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take Photo'),
              onTap: () {
                Navigator.pop(context);
                // Implement camera
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.pop(context);
                // Implement gallery picker
              },
            ),
          ],
        ),
      ),
    );
  }

  void _addCertification() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Certification'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Certification Name',
            hintText: 'e.g., Licensed Professional Counselor',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                setState(() {
                  _certifications.add(controller.text);
                });
                Navigator.pop(context);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _uploadDocuments() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Upload Documents'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Please upload the following documents:'),
            SizedBox(height: 16),
            Text('• Professional License'),
            Text('• Certification Documents'),
            Text('• ID Verification'),
            SizedBox(height: 16),
            Text(
              'Documents will be reviewed within 24-48 hours.',
              style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              // POST /api/providers/{id}/documents
              showSuccessSnackBar(context, 'Documents uploaded successfully');
            },
            icon: const Icon(Icons.upload_file),
            label: const Text('Choose Files'),
          ),
        ],
      ),
    );
  }

  void _saveProfile() {
    if (_formKey.currentState?.validate() ?? false) {
      // POST /api/providers/{id}/profile
      showSuccessSnackBar(context, 'Profile updated successfully');
      Navigator.pop(context);
    }
  }
}
