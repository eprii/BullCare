import 'package:flutter/material.dart';

import '../../models/activity_definition.dart';
import '../../models/bull_model.dart';
import '../../models/user_model.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_page_container.dart';
import '../../widgets/bull_avatar.dart';
import '../../widgets/empty_state.dart';
import 'activity_form_page.dart';

class ActivityTypePage extends StatelessWidget {
  const ActivityTypePage({
    super.key,
    required this.bull,
    required this.user,
  });

  final BullModel bull;
  final UserModel user;

  @override
  Widget build(BuildContext context) {
    if (!user.isPetugas) {
      return Scaffold(
        backgroundColor: AppTheme.background,
        appBar: AppBar(title: const Text('Aktivitas')),
        body: const AppPageContainer(
          maxWidth: 760,
          child: Center(
            child: EmptyState(
              icon: Icons.visibility_outlined,
              title: 'Mode Supervisor',
              message: 'Supervisor hanya dapat melihat aktivitas dan tidak dapat mencatat aktivitas baru.',
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(title: const Text('Pilih Jenis Aktivitas')),
      body: AppPageContainer(
        maxWidth: 760,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(0, 12, 0, 28),
          children: <Widget>[
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppTheme.divider),
              ),
              child: Row(
                children: <Widget>[
                  BullAvatar(name: bull.nama, size: 62),
                  const SizedBox(width: 13),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          bull.kode_bull,
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.w900),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '${bull.nama} • Kandang ${bull.nomor_kandang}',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            Text(
              'Aktivitas Pemeliharaan',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 4),
            Text(
              'Pilih aktivitas yang akan dicatat untuk bull ini.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 14),
            LayoutBuilder(
              builder: (context, constraints) {
                final int columns = constraints.maxWidth >= 640 ? 3 : 2;
                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: ActivityCatalog.all.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: columns,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: columns == 3 ? 1.25 : 1.0,
                  ),
                  itemBuilder: (context, index) {
                    final ActivityDefinition definition =
                        ActivityCatalog.all[index];
                    return _ActivityTypeCard(
                      definition: definition,
                      onTap: () async {
                        final bool? saved = await Navigator.of(context).push<bool>(
                          MaterialPageRoute<bool>(
                            builder: (_) => ActivityFormPage(
                              bull: bull,
                              user: user,
                              definition: definition,
                            ),
                          ),
                        );
                        if (saved == true && context.mounted) {
                          Navigator.of(context).pop(definition.label);
                        }
                      },
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _ActivityTypeCard extends StatelessWidget {
  const _ActivityTypeCard({
    required this.definition,
    required this.onTap,
  });

  final ActivityDefinition definition;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppTheme.divider),
            boxShadow: const <BoxShadow>[
              BoxShadow(
                color: Color(0x0A000000),
                blurRadius: 14,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppTheme.primarySoft,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  definition.icon,
                  color: AppTheme.primary,
                  size: 24,
                ),
              ),
              const Spacer(),
              Text(
                definition.label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
              ),
              const SizedBox(height: 5),
              const Row(
                children: <Widget>[
                  Text(
                    'Isi formulir',
                    style: TextStyle(
                      color: AppTheme.primary,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Spacer(),
                  Icon(
                    Icons.arrow_forward_rounded,
                    size: 18,
                    color: AppTheme.primary,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
