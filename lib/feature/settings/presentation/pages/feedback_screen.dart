import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:auto_route/auto_route.dart';
import 'package:mailto/mailto.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/router/router.gr.dart';
import '../../../../generated/l10n.dart';

@RoutePage()
class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({super.key});

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _messageController = TextEditingController();
  bool _isSending = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _sendFeedback() async {
    if (_nameController.text.trim().isEmpty ||
        _emailController.text.trim().isEmpty ||
        _messageController.text.trim().isEmpty) {
      showCupertinoDialog(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: Text(Locales.current.error),
          content: Text(Locales.current.please_fill_all_fields),
          actions: [
            CupertinoDialogAction(
              child: const Text('OK'),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      );
      return;
    }

    setState(() => _isSending = true);

    try {
      // Создаем mailto ссылку
      final mailtoLink = Mailto(
        to: ['petrfalkovsky@yandex.ru'],
        subject: 'AI Cleaner Feedback from ${_nameController.text}',
        body: '''
Name: ${_nameController.text}
Email: ${_emailController.text}

Message:
${_messageController.text}
''',
      );

      await launchUrl(Uri.parse(mailtoLink.toString()));

      if (mounted) {
        setState(() => _isSending = false);
        context.router.replace(const FeedbackSuccessRoute());
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSending = false);
        showCupertinoDialog(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: Text(Locales.current.error),
            content: Text(Locales.current.failed_to_send_feedback),
            actions: [
              CupertinoDialogAction(
                child: const Text('OK'),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF0A0E27),
      child: CupertinoPageScaffold(
        backgroundColor: const Color(0xFF0A0E27),
        navigationBar: CupertinoNavigationBar(
          backgroundColor: Colors.transparent,
          border: null,
          leading: CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: () => context.router.maybePop(),
            child: const Icon(CupertinoIcons.back, color: Colors.white),
          ),
          middle: Text(
            Locales.current.contact_and_feedback,
            style: const TextStyle(color: Colors.white),
          ),
        ),
        child: SafeArea(
          child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const SizedBox(height: 20),
            Text(
              Locales.current.we_love_to_hear_from_you,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              Locales.current.send_us_your_feedback,
              style: TextStyle(
                color: Colors.white.withOpacity(0.6),
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),

            // Имя
            _buildInputField(
              label: Locales.current.name,
              controller: _nameController,
              placeholder: Locales.current.enter_your_name,
              icon: CupertinoIcons.person,
            ),
            const SizedBox(height: 16),

            // Email
            _buildInputField(
              label: Locales.current.email,
              controller: _emailController,
              placeholder: Locales.current.enter_your_email,
              icon: CupertinoIcons.mail,
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),

            // Сообщение
            _buildInputField(
              label: Locales.current.message,
              controller: _messageController,
              placeholder: Locales.current.enter_your_message,
              icon: CupertinoIcons.chat_bubble_text,
              maxLines: 6,
            ),
            const SizedBox(height: 32),

            // Кнопка отправки
            Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: CupertinoButton(
                padding: const EdgeInsets.symmetric(vertical: 16),
                onPressed: _isSending ? null : _sendFeedback,
                child: _isSending
                    ? const CupertinoActivityIndicator(color: Colors.white)
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            CupertinoIcons.paperplane,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            Locales.current.send_feedback,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
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

  Widget _buildInputField({
    required String label,
    required TextEditingController controller,
    required String placeholder,
    required IconData icon,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.white.withOpacity(0.1),
              width: 1,
            ),
          ),
          child: Row(
            crossAxisAlignment:
                maxLines > 1 ? CrossAxisAlignment.start : CrossAxisAlignment.center,
            children: [
              Padding(
                padding: EdgeInsets.only(
                  left: 16,
                  top: maxLines > 1 ? 16 : 0,
                ),
                child: Icon(
                  icon,
                  color: Colors.white.withOpacity(0.5),
                  size: 20,
                ),
              ),
              Expanded(
                child: CupertinoTextField(
                  controller: controller,
                  placeholder: placeholder,
                  placeholderStyle: TextStyle(
                    color: Colors.white.withOpacity(0.3),
                  ),
                  style: const TextStyle(color: Colors.white),
                  decoration: null,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  maxLines: maxLines,
                  keyboardType: keyboardType,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
