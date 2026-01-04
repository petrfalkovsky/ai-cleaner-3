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
  bool _isFormValid = false;

  @override
  void initState() {
    super.initState();
    // Слушаем изменения в полях для валидации
    _nameController.addListener(_validateForm);
    _emailController.addListener(_validateForm);
    _messageController.addListener(_validateForm);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  /// Проверка валидности формы
  void _validateForm() {
    final isValid = _isNameValid() && _isEmailValid() && _isMessageValid();
    if (isValid != _isFormValid) {
      setState(() {
        _isFormValid = isValid;
      });
    }
  }

  /// Проверка имени
  bool _isNameValid() {
    return _nameController.text.trim().isNotEmpty;
  }

  /// Проверка email
  bool _isEmailValid() {
    final email = _emailController.text.trim();
    if (email.isEmpty) return false;

    // Регулярное выражение для валидации email
    final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    return emailRegex.hasMatch(email);
  }

  /// Проверка сообщения
  bool _isMessageValid() {
    return _messageController.text.trim().isNotEmpty;
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
        to: ['clarapadilla184@outlook.com'],
        subject: 'AI Cleaner Feedback from ${_nameController.text}',
        body:
            '''
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
      child: GestureDetector(
        // Скрываем клавиатуру при тапе на пустое место
        onTap: () => FocusScope.of(context).unfocus(),
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
                // const SizedBox(height: 8),
                // Text(
                //   Locales.current.send_us_your_feedback,
                //   style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 16),
                //   textAlign: TextAlign.center,
                // ),
                const SizedBox(height: 20),

                // Имя
                _buildInputField(
                  label: Locales.current.name,
                  controller: _nameController,
                  placeholder: Locales.current.enter_your_name,
                  icon: CupertinoIcons.person,
                ),
                const SizedBox(height: 16),

                // Email с индикатором валидности
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInputField(
                      label: Locales.current.email,
                      controller: _emailController,
                      placeholder: Locales.current.enter_your_email,
                      icon: CupertinoIcons.mail,
                      keyboardType: TextInputType.emailAddress,
                      suffixIcon: _emailController.text.isNotEmpty
                          ? (_isEmailValid()
                                ? const Icon(
                                    CupertinoIcons.check_mark_circled_solid,
                                    color: Color(0xFF34C759),
                                    size: 20,
                                  )
                                : const Icon(
                                    CupertinoIcons.xmark_circle_fill,
                                    color: Color(0xFFFF3B30),
                                    size: 20,
                                  ))
                          : null,
                    ),
                    if (_emailController.text.isNotEmpty && !_isEmailValid())
                      Padding(
                        padding: const EdgeInsets.only(left: 4, top: 4),
                        child: Text(
                          'Введите корректный email',
                          style: TextStyle(
                            color: const Color(0xFFFF3B30).withOpacity(0.8),
                            fontSize: 12,
                          ),
                        ),
                      ),
                  ],
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
                Opacity(
                  opacity: _isFormValid && !_isSending ? 1.0 : 0.5,
                  child: Container(
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
                      onPressed: (_isFormValid && !_isSending) ? _sendFeedback : null,
                      child: _isSending
                          ? const CupertinoActivityIndicator(color: Colors.white)
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(CupertinoIcons.paperplane, color: Colors.white),
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
                ),
              ],
            ),
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
    Widget? suffixIcon,
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
            border: Border.all(color: Colors.white.withOpacity(0.1), width: 1),
          ),
          child: Row(
            crossAxisAlignment: maxLines > 1 ? CrossAxisAlignment.start : CrossAxisAlignment.center,
            children: [
              Padding(
                padding: EdgeInsets.only(left: 16, top: maxLines > 1 ? 16 : 0),
                child: Icon(icon, color: Colors.white.withOpacity(0.5), size: 20),
              ),
              Expanded(
                child: CupertinoTextField(
                  controller: controller,
                  placeholder: placeholder,
                  placeholderStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
                  style: const TextStyle(color: Colors.white),
                  decoration: null,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  maxLines: maxLines,
                  keyboardType: keyboardType,
                  suffix: suffixIcon != null
                      ? Padding(padding: const EdgeInsets.only(right: 12), child: suffixIcon)
                      : null,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
