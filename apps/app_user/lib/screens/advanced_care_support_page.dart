import 'package:flutter/material.dart';

import 'package:common/widgets/widgets.dart';

class AdvancedCareSupportPage extends StatefulWidget {
  const AdvancedCareSupportPage({super.key});

  @override
  State<AdvancedCareSupportPage> createState() =>
      _AdvancedCareSupportPageState();
}

class _AdvancedCareSupportPageState extends State<AdvancedCareSupportPage> {
  final List<Map<String, dynamic>> _services = [
    {
      'title': 'Professional Counseling',
      'icon': Icons.person_outline,
      'description':
          'Connect with licensed therapists and counselors for personalized mental health support.',
      'benefits': [
        'One-on-one sessions',
        'Personalized treatment plans',
        'Confidential support',
        'Flexible scheduling'
      ],
    },
    {
      'title': 'Psychiatric Consultation',
      'icon': Icons.medical_services_outlined,
      'description':
          'Expert psychiatric evaluation and medication management when needed.',
      'benefits': [
        'Clinical assessment',
        'Medication guidance',
        'Crisis intervention',
        'Treatment planning'
      ],
    },
    {
      'title': 'Family Therapy',
      'icon': Icons.people_outline,
      'description':
          'Strengthen relationships and improve communication with family members.',
      'benefits': [
        'Family sessions',
        'Conflict resolution',
        'Communication skills',
        'Support networks'
      ],
    },
    {
      'title': 'Group Support Sessions',
      'icon': Icons.groups_outlined,
      'description':
          'Share experiences and learn from others in structured support groups.',
      'benefits': [
        'Peer support',
        'Shared experiences',
        'Community building',
        'Emotional growth'
      ],
    },
  ];

  final List<Map<String, String>> _specialists = [
    {
      'name': 'Dr. Sarah Johnson',
      'specialization': 'Clinical Psychology',
      'experience': '15+ years',
      'availability': 'Available Now'
    },
    {
      'name': 'Dr. Rajesh Patel',
      'specialization': 'Psychiatry',
      'experience': '12+ years',
      'availability': 'Available Today'
    },
    {
      'name': 'Emma Wilson',
      'specialization': 'Family Therapy',
      'experience': '10+ years',
      'availability': 'Available Tomorrow'
    },
    {
      'name': 'Dr. Priya Kumar',
      'specialization': 'Crisis Intervention',
      'experience': '8+ years',
      'availability': 'Available Now'
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Advanced Care Support'),
        backgroundColor: _Palette.primary,
        elevation: 0,
      ),
      backgroundColor: _Palette.bg,
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: _Palette.primary,
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Professional Guidance When You Need It',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Connect with specialized healthcare professionals for comprehensive mental health support and treatment.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white70,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            showSuccessSnackBar(context, 'Booking feature coming soon');
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: _Palette.primary,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Book Appointment',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {},
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: const BorderSide(color: Colors.white),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Learn More',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Our Services',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: _Palette.text,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _services.length,
                    itemBuilder: (context, index) {
                      final service = _services[index];
                      return Card(
                        color: _Palette.cardBg,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        margin: const EdgeInsets.only(bottom: 12),
                        elevation: 2,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: _Palette.primary.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(
                                      service['icon'] as IconData,
                                      color: _Palette.primary,
                                      size: 24,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          service['title'] as String,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            color: _Palette.text,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          service['description'] as String,
                                          style: const TextStyle(
                                            fontSize: 13,
                                            color: _Palette.subtext,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Icon(
                                    Icons.arrow_forward_ios,
                                    size: 16,
                                    color: _Palette.subtext,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: (service['benefits'] as List<String>)
                                    .map(
                                      (benefit) => Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: _Palette.soft,
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          benefit,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: _Palette.primary,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    )
                                    .toList(),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Our Specialists',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: _Palette.text,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _specialists.length,
                    itemBuilder: (context, index) {
                      final specialist = _specialists[index];
                      return Card(
                        color: _Palette.cardBg,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        margin: const EdgeInsets.only(bottom: 12),
                        elevation: 2,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 28,
                                backgroundColor: _Palette.primary.withOpacity(0.1),
                                child: Text(
                                  specialist['name']!
                                      .split(' ')
                                      .map((e) => e[0])
                                      .join(),
                                  style: const TextStyle(
                                    color: _Palette.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      specialist['name']!,
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                        color: _Palette.text,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      specialist['specialization']!,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: _Palette.subtext,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.star,
                                          size: 14,
                                          color: Colors.amber,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          specialist['experience']!,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: _Palette.subtext,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: _Palette.soft,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  specialist['availability']!,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: _Palette.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Why Choose Our Program',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: _Palette.text,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildFeatureCard(
                    'Licensed Professionals',
                    'All therapists and counselors are fully licensed and certified.',
                    Icons.verified_user,
                  ),
                  const SizedBox(height: 12),
                  _buildFeatureCard(
                    'Confidential & Secure',
                    'Your privacy is our priority with HIPAA-compliant security.',
                    Icons.security,
                  ),
                  const SizedBox(height: 12),
                  _buildFeatureCard(
                    'Flexible Scheduling',
                    'Book appointments at times that work for your schedule.',
                    Icons.schedule,
                  ),
                  const SizedBox(height: 12),
                  _buildFeatureCard(
                    'Evidence-Based Treatment',
                    'Proven therapeutic approaches backed by research.',
                    Icons.science,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Card(
                color: _Palette.soft,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      const Text(
                        'Ready to Get Started?',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: _Palette.text,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Take the first step towards better mental health today.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: _Palette.subtext,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          showSuccessSnackBar(context, 'Booking feature coming soon');
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _Palette.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Schedule Your Consultation',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureCard(String title, String description, IconData icon) {
    return Card(
      color: _Palette.cardBg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _Palette.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: _Palette.primary,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: _Palette.text,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: const TextStyle(
                      fontSize: 13,
                      color: _Palette.subtext,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Palette {
  static const primary = Color(0xFF8B5FBF);
  static const bg = Color(0xFFFDFBFF);
  static const cardBg = Color(0xFFFFFFFF);
  static const text = Color(0xFF1A1B41);
  static const subtext = Color(0xFF6B6B8E);
  static const soft = Color(0xFFF0EBFF);
}

