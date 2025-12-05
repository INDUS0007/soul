import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import 'package:common/api/api_client.dart';
import 'package:common/widgets/widgets.dart';

class AIAssessmentPage extends StatefulWidget {
  const AIAssessmentPage({super.key});

  @override
  State<AIAssessmentPage> createState() => _AIAssessmentPageState();
}

class _AIAssessmentPageState extends State<AIAssessmentPage> {
  final ApiClient _apiClient = ApiClient();
  final Random _random = Random();
  
  // Original questions with options in score order (0=lowest, 4=highest)
  static const List<_AssessmentQuestion> _originalQuestions = [
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

  // Shuffled options with their original score indices
  // Each question has a list of (displayText, originalScoreIndex) pairs
  late List<List<_ShuffledOption>> _shuffledOptions;
  
  // Maps questionIndex -> selected answer text
  final Map<int, String> _selectedAnswers = {};
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _shuffleAllOptions();
  }

  void _shuffleAllOptions() {
    _shuffledOptions = _originalQuestions.map((question) {
      // Create list of options with their original indices
      final options = question.options.asMap().entries.map((entry) {
        return _ShuffledOption(text: entry.value, originalIndex: entry.key);
      }).toList();
      // Shuffle the options
      options.shuffle(_random);
      return options;
    }).toList();
  }

  Future<void> _handleAssessment() async {
    if (_selectedAnswers.length < _originalQuestions.length) {
      showErrorSnackBar(context, 'Please answer all questions before getting your assessment.');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Submit assessment to backend API using actual answer text
      final result = await _apiClient.submitAssessment(
        feelingResponse: _selectedAnswers[0] ?? '',
        sleepQualityResponse: _selectedAnswers[1] ?? '',
        anxietyFrequencyResponse: _selectedAnswers[2] ?? '',
        energyLevelResponse: _selectedAnswers[3] ?? '',
        supportFeelingResponse: _selectedAnswers[4] ?? '',
        stressManagementResponse: _selectedAnswers[5] ?? '',
      );

      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      // Show results from backend response
      await showDialog<void>(
        context: context,
        builder: (dialogContext) {
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
                  'Mood score: ${result.moodScore}/100',
                  style: Theme.of(dialogContext).textTheme.titleMedium?.copyWith(
                        color: const Color(0xFF007A78),
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 12),
                Text(result.feedbackMessage),
                const SizedBox(height: 16),
                Text(
                  'Tip: ${result.feedbackTip}',
                  style: Theme.of(dialogContext).textTheme.bodyMedium?.copyWith(
                        fontStyle: FontStyle.italic,
                        color: const Color(0xFF155E75),
                      ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                  Navigator.of(context).pop(); // Go back to previous screen
                },
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF666666),
                ),
                child: const Text('Back'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop();
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
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      // Fallback to local calculation if API fails
      // Calculate scores from answers locally
      final scores = _selectedAnswers.entries.map((entry) {
        final options = _originalQuestions[entry.key].options;
        return options.indexOf(entry.value);
      }).toList();
      
      final double averageScore = scores.reduce((a, b) => a + b) / scores.length;
      final int moodScore = (averageScore / (_maxOptionIndex + 1) * 100).round();
      final _AssessmentFeedback feedback = _generateFeedback(moodScore);

      showErrorSnackBar(context, 'Could not save assessment to server. Showing local results.');

      await showDialog<void>(
        context: context,
        builder: (dialogContext) {
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
                  style: Theme.of(dialogContext).textTheme.titleMedium?.copyWith(
                        color: const Color(0xFF007A78),
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 12),
                Text(feedback.message),
                const SizedBox(height: 16),
                Text(
                  'Tip: ${feedback.tip}',
                  style: Theme.of(dialogContext).textTheme.bodyMedium?.copyWith(
                        fontStyle: FontStyle.italic,
                        color: const Color(0xFF155E75),
                      ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                  Navigator.of(context).pop(); // Go back to previous screen
                },
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF666666),
                ),
                child: const Text('Back'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop();
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
  }

  void _retakeAssessment() {
    setState(() {
      _selectedAnswers.clear();
      _shuffleAllOptions(); // Shuffle options for retake
      _isLoading = false;
    });
  }

  _AssessmentFeedback _generateFeedback(int score) {
    if (score == 100) {
      return const _AssessmentFeedback(
        message:
            '🎉 Wow! You achieved a perfect score! You are in an amazing state of wellbeing!',
        tip:
            'Keep doing what you\'re doing - you\'re truly thriving! Consider sharing your positive energy with others.',
      );
    } else if (score >= 90) {
      return const _AssessmentFeedback(
        message:
            '🌟 Outstanding! You are in an excellent state of mental wellbeing!',
        tip:
            'Your positive habits are clearly working. Keep nurturing your wellbeing and inspire others around you.',
      );
    } else if (score >= 80) {
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

  int get _maxOptionIndex => _originalQuestions.first.options.length - 1;

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
                ..._originalQuestions.asMap().entries.map(
                      (entry) => Padding(
                        padding: const EdgeInsets.only(bottom: 20),
                        child: _ShuffledQuestionCard(
                          questionText: entry.value.text,
                          shuffledOptions: _shuffledOptions[entry.key],
                          selectedAnswerText: _selectedAnswers[entry.key],
                          onOptionSelected: (answerText) {
                            setState(() {
                              _selectedAnswers[entry.key] = answerText;
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

/// Represents a shuffled option with its display text and original score index
class _ShuffledOption {
  const _ShuffledOption({required this.text, required this.originalIndex});

  final String text;
  final int originalIndex; // The score value (0-4)
}

class _ShuffledQuestionCard extends StatelessWidget {
  const _ShuffledQuestionCard({
    required this.questionText,
    required this.shuffledOptions,
    required this.selectedAnswerText,
    required this.onOptionSelected,
  });

  final String questionText;
  final List<_ShuffledOption> shuffledOptions;
  final String? selectedAnswerText; // The answer text that was selected
  final ValueChanged<String> onOptionSelected; // Called with answer text

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
              questionText,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF0A3C4C),
                  ),
            ),
            const SizedBox(height: 12),
            ...shuffledOptions.map(
                  (option) => RadioListTile<String>(
                    contentPadding: EdgeInsets.zero,
                    activeColor: const Color(0xFF007A78),
                    title: Text(option.text),
                    value: option.text,
                    groupValue: selectedAnswerText,
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

