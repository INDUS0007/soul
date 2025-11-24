import 'dart:async';

import 'package:flutter/material.dart';

import 'package:common/widgets/widgets.dart';

class AIAssessmentPage extends StatefulWidget {
  const AIAssessmentPage({super.key});

  @override
  State<AIAssessmentPage> createState() => _AIAssessmentPageState();
}

class _AIAssessmentPageState extends State<AIAssessmentPage> {
  final List<_AssessmentQuestion> _questions = const [
    _AssessmentQuestion(
      text: 'How have you been feeling lately?',
      options: ['Very low', 'Low', 'Neutral', 'Positive', 'Very positive'],
    ),
    _AssessmentQuestion(
      text: 'How is your sleep quality?',
      options: ['Poor', 'Fair', 'Average', 'Good', 'Excellent'],
    ),
    _AssessmentQuestion(
      text: 'How often do you feel anxious?',
      options: ['Rarely', 'Sometimes', 'Often', 'Very often', 'Always'],
    ),
    _AssessmentQuestion(
      text: 'How energized do you feel during the day?',
      options: ['Exhausted', 'Low', 'Moderate', 'Energized', 'Very energized'],
    ),
    _AssessmentQuestion(
      text: 'How supported do you feel by people around you?',
      options: ['Not at all', 'Rarely', 'Sometimes', 'Often', 'Always'],
    ),
    _AssessmentQuestion(
      text: 'How well are you managing stress right now?',
      options: [
        'Overwhelmed',
        'Struggling',
        'Coping',
        'Managing well',
        'Thriving',
      ],
    ),
  ];

  final Map<int, int> _selectedOptions = {};
  bool _isLoading = false;

  Future<void> _handleAssessment() async {
    if (_selectedOptions.length < _questions.length) {
      showErrorSnackBar(context, 'Please answer all questions before getting your assessment.');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    await Future<void>.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });

    final double averageScore =
        _selectedOptions.values.reduce((a, b) => a + b) /
            _selectedOptions.values.length;
    final int moodScore = (averageScore / (_maxOptionIndex + 1) * 100).round();
    final _AssessmentFeedback feedback = _generateFeedback(moodScore);

    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFFE6F7F8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text('Your AI Assessment'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Mood score: $moodScore/100',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: const Color(0xFF007A78),
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 12),
              Text(feedback.message),
              const SizedBox(height: 16),
              Text(
                'Tip: ${feedback.tip}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontStyle: FontStyle.italic,
                      color: const Color(0xFF155E75),
                    ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _retakeAssessment();
              },
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF007A78),
              ),
              child: const Text('Retake Assessment'),
            ),
          ],
        );
      },
    );
  }

  void _retakeAssessment() {
    setState(() {
      _selectedOptions.clear();
      _isLoading = false;
    });
  }

  _AssessmentFeedback _generateFeedback(int score) {
    if (score >= 80) {
      return const _AssessmentFeedback(
        message:
            'You appear to be in a positive and stable mood. Keep nurturing your wellbeing.',
        tip:
            'Continue your habits that work well—perhaps share your positivity with someone today.',
      );
    } else if (score >= 60) {
      return const _AssessmentFeedback(
        message: 'You seem slightly stressed but generally balanced.',
        tip: 'Try a short mindfulness break or journaling to stay grounded.',
      );
    } else if (score >= 40) {
      return const _AssessmentFeedback(
        message: 'You may be experiencing some stress or low mood right now.',
        tip:
            'Consider reaching out to a friend and practicing deep breathing today.',
      );
    } else {
      return const _AssessmentFeedback(
        message: 'Your responses suggest notable stress or low mood.',
        tip:
            'It might help to speak with someone you trust or a mental health professional.',
      );
    }
  }

  int get _maxOptionIndex => _questions.first.options.length - 1;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1FAFB),
      appBar: AppBar(
        backgroundColor: const Color(0xFF007A78),
        title: const Text('AI Mental Health Check'),
      ),
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Take a moment to reflect on how you\'re doing. Answer a few quick questions to receive AI-guided insights on your mood and stress levels.',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: const Color(0xFF0A3C4C),
                        ),
                  ),
                  const SizedBox(height: 24),
                  ..._questions.asMap().entries.map(
                        (entry) => Padding(
                          padding: const EdgeInsets.only(bottom: 20),
                          child: _QuestionCard(
                            question: entry.value,
                            selectedIndex: _selectedOptions[entry.key],
                            onOptionSelected: (index) {
                              setState(() {
                                _selectedOptions[entry.key] = index;
                              });
                            },
                          ),
                        ),
                      ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _handleAssessment,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF007A78),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Get My Assessment',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      onPressed: _isLoading ? null : _retakeAssessment,
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFF0A6C74),
                      ),
                      child: const Text('Retake Assessment'),
                    ),
                  ),
                ],
              ),
            ),
            if (_isLoading)
              Container(
                color: const Color.fromRGBO(0, 0, 0, 0.1),
                child: const Center(child: _LoadingCard()),
              ),
          ],
        ),
      ),
    );
  }
}

class _QuestionCard extends StatelessWidget {
  const _QuestionCard({
    required this.question,
    required this.selectedIndex,
    required this.onOptionSelected,
  });

  final _AssessmentQuestion question;
  final int? selectedIndex;
  final ValueChanged<int> onOptionSelected;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      elevation: 2,
      shadowColor: const Color(0x33007A78),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              question.text,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF0A3C4C),
                  ),
            ),
            const SizedBox(height: 12),
            ...question.options.asMap().entries.map(
                  (entry) => RadioListTile<int>(
                    contentPadding: EdgeInsets.zero,
                    activeColor: const Color(0xFF007A78),
                    title: Text(entry.value),
                    value: entry.key,
                    groupValue: selectedIndex,
                    onChanged: (value) {
                      if (value != null) {
                        onOptionSelected(value);
                      }
                    },
                  ),
                ),
          ],
        ),
      ),
    );
  }
}

class _LoadingCard extends StatelessWidget {
  const _LoadingCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 8,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            CircularProgressIndicator(color: Color(0xFF007A78)),
            SizedBox(height: 16),
            Text('Analyzing your responses...'),
          ],
        ),
      ),
    );
  }
}

class _AssessmentQuestion {
  const _AssessmentQuestion({required this.text, required this.options});

  final String text;
  final List<String> options;
}

class _AssessmentFeedback {
  const _AssessmentFeedback({required this.message, required this.tip});

  final String message;
  final String tip;
}

