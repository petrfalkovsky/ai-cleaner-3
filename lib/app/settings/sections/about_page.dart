import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import '../../../core/app_info/app_info.dart';
import '../../../core/extensions/core_extensions.dart';
import '../../../core/theme/text_extension.dart';
import '../../../core/widgets/custom_appbar.dart';
@RoutePage()
class AboutPage extends StatelessWidget {
  const AboutPage({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppbar(title: 'about drift.'),
      extendBodyBehindAppBar: true,
      extendBody: true,
      body: SingleChildScrollView(
        child: SafeArea(
          child: Column(
            spacing: 16,
            children: [
              const AboutItem(
                title: 'what is whoami?',
                subtitle:
                    'whoami is a private journaling app that helps you document life as seen through your eyes. each entry has a photo, a track and your thoughts to help you capture the moment.',
              ),
              const AboutItem(
                title: 'how was it developed?',
                subtitle:
                    'the app was developed using the strict principles of VDD (Vibes Driven Development). A methodology invented under the influence of sleep deprivation, the crushing fear of death and an unknown internal urge.',
              ),
              const AboutItem(
                title: 'is it free?',
                subtitle:
                    'the app is and will remain free to use. there are not hidden fees, ads or subscriptions.',
              ),
              const AboutItem(
                title: 'about your data',
                subtitle:
                    'as of now your data is stored in a secure database. the app does not collect any personal information. the app does not track you. the app does not share your data with any third party services. the app does not have any analytics. the app does not have any ads. the app does not have any tracking.',
              ),
              const AboutItem(
                title: 'are my entries encrypted?',
                subtitle:
                    'as of now, the entries are not encrypted. the app is in its early stages and encryption is a feature that will be added in the future.',
              ),
              AboutItem(
                title: 'version',
                subtitle:
                    '${AppInfo.instance.packageInfo.version}+${AppInfo.instance.packageInfo.buildNumber}',
              ),
              const Gap(0),
            ],
          ).p(all: 16),
        ),
      ),
    );
  }
}
class AboutItem extends StatelessWidget {
  const AboutItem({super.key, required this.title, required this.subtitle});
  final String title;
  final String subtitle;
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("> $title").titleSmall(),
        const Gap(12),
        Container(
          padding: const EdgeInsets.all(16.0),
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12.0),
            border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
          ),
          child: Text(subtitle).bodySmall(fontSize: 14, opacity: 0.9),
        ),
      ],
    );
  }
}