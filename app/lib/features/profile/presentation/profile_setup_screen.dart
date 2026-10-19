import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/theme/tokens.dart';
import '../../../core/utils/vi_normalize.dart';
import '../../../core/widgets/widgets.dart';
import '../../../l10n/app_localizations.dart';
import '../../auth/presentation/auth_state.dart';
import '../../settings/presentation/locale_provider.dart';
import '../domain/profile_validation.dart';
import '../domain/provinces.dart';
import '../domain/user_profile.dart';
import 'profile_providers.dart';

/// Screen 02 (ACC-02/03/04): onboarding profile; also used to edit from
/// Settings ("Sửa").
class ProfileSetupScreen extends ConsumerStatefulWidget {
  const ProfileSetupScreen({super.key, this.avatarPicker});

  /// Override in tests; defaults to image_picker (gallery).
  final Future<Uint8List?> Function()? avatarPicker;

  @override
  ConsumerState<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends ConsumerState<ProfileSetupScreen> {
  final _name = TextEditingController();
  String? _provinceCode;
  Experience _experience = Experience.beginner;
  String _lang = 'vi';
  Uint8List? _avatarBytes;
  bool _editing = false; // true when a complete profile already exists
  bool _initialised = false;
  bool _saving = false;
  bool _submitted = false;
  String? _saveError;

  @override
  void initState() {
    super.initState();
    _lang = ref.read(localeProvider).languageCode;
    _name.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _prefill(UserProfile? p) {
    if (_initialised) return;
    _initialised = true;
    if (p == null) return;
    _editing = p.isComplete;
    _name.text = p.displayName;
    _provinceCode = p.provinceCode;
    _experience = p.experience;
    _lang = p.lang;
  }

  Future<void> _pickAvatar() async {
    final picker =
        widget.avatarPicker ??
        () async {
          final f = await ImagePicker().pickImage(
            source: ImageSource.gallery,
            maxWidth: 512,
            maxHeight: 512,
            imageQuality: 80,
          );
          return f?.readAsBytes();
        };
    final bytes = await picker();
    if (bytes != null && mounted) setState(() => _avatarBytes = bytes);
  }

  Future<void> _pickProvince() async {
    final l10n = AppLocalizations.of(context);
    final picked = await showModalBottomSheet<Province>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadius.card),
        ),
      ),
      builder: (_) => _ProvinceSheet(hint: l10n.profileProvinceSearch),
    );
    if (picked != null) setState(() => _provinceCode = picked.code);
  }

  Future<void> _submit() async {
    setState(() {
      _submitted = true;
      _saveError = null;
    });
    final errors = ProfileValidation.validate(
      displayName: _name.text,
      provinceCode: _provinceCode,
      lang: _lang,
    );
    if (errors.isNotEmpty) return;
    final l10n = AppLocalizations.of(context);
    final uid = ref.read(authRepositoryProvider).currentUserId;
    if (uid == null) return;
    setState(() => _saving = true);
    try {
      final existing = ref.read(profileProvider).value;
      String? avatarPath = existing?.avatarPath;
      if (_avatarBytes != null) {
        try {
          avatarPath = await ref
              .read(profileRepositoryProvider)
              .uploadAvatar(_avatarBytes!);
        } catch (_) {
          // Avatar is optional: keep going without it.
        }
      }
      final profile = UserProfile(
        id: uid,
        displayName: _name.text.trim(),
        avatarPath: avatarPath,
        lang: _lang,
        timezone: existing?.timezone ?? kDefaultTimezone,
        provinceCode: _provinceCode,
        experience: _experience,
      );
      await ref.read(profileProvider.notifier).save(profile);
      await ref.read(localeProvider.notifier).set(_lang);
      if (mounted) context.go('/today');
    } catch (_) {
      if (mounted) setState(() => _saveError = l10n.profileSaveError);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String? _errorText(AppLocalizations l10n, Set<ProfileError> errors) {
    if (!_submitted) return null;
    if (errors.contains(ProfileError.nameEmpty)) return l10n.errorNameEmpty;
    if (errors.contains(ProfileError.nameTooLong)) return l10n.errorNameTooLong;
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = Theme.of(context).textTheme;
    final profileAsync = ref.watch(profileProvider);
    if (profileAsync.hasValue) _prefill(profileAsync.value);
    final errors = ProfileValidation.validate(
      displayName: _name.text,
      provinceCode: _provinceCode,
      lang: _lang,
    );
    final province = provinceByCode(_provinceCode);
    final initial = _name.text.trim().isEmpty
        ? '?'
        : _name.text.trim().characters.first.toUpperCase();

    return GlassScaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (context.canPop())
                      IconButton(
                        onPressed: () => context.pop(),
                        icon: const Icon(Icons.chevron_left_rounded),
                      ),
                    if (!_editing)
                      Text(
                        l10n.profileStep,
                        style: t.labelLarge?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                  ],
                ),
                if (!_editing) ...[
                  const SizedBox(height: AppSpacing.sm),
                  const Row(
                    children: [
                      Expanded(child: AppProgressBar(value: 1, height: 4)),
                      SizedBox(width: AppSpacing.sm),
                      Expanded(child: AppProgressBar(value: 0, height: 4)),
                    ],
                  ),
                ],
                const SizedBox(height: AppSpacing.xl),
                Text(
                  l10n.profileTitle,
                  style: t.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  l10n.profileSub,
                  style: t.bodyMedium?.copyWith(color: AppColors.textSecondary),
                ),
                const SizedBox(height: AppSpacing.xl),
                Row(
                  children: [
                    CircleAvatar(
                      radius: 32,
                      backgroundColor: AppColors.greenSoft,
                      backgroundImage: _avatarBytes == null
                          ? null
                          : MemoryImage(_avatarBytes!),
                      child: _avatarBytes == null
                          ? Text(
                              initial,
                              style: t.titleLarge?.copyWith(
                                color: AppColors.green,
                                fontWeight: FontWeight.w700,
                              ),
                            )
                          : null,
                    ),
                    const SizedBox(width: AppSpacing.lg),
                    Flexible(
                      child: GlowButton(
                        key: const Key('avatar-button'),
                        label: l10n.profileChangeAvatar,
                        variant: GlowButtonVariant.secondary,
                        expanded: false,
                        onPressed: _pickAvatar,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xl),
                GlassTextField(
                  key: const Key('name-field'),
                  controller: _name,
                  label: l10n.profileNameLabel,
                  maxLength: kMaxDisplayNameLength + 10,
                  errorText: _errorText(l10n, errors),
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  l10n.profileLocationLabel,
                  style: t.labelLarge?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: AppSpacing.sm),
                GlassCard(
                  key: const Key('province-field'),
                  onTap: _pickProvince,
                  radius: AppRadius.chip,
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          province?.name ?? l10n.profileLocationHint,
                          style: t.bodyLarge?.copyWith(
                            color: province == null
                                ? AppColors.textSecondary
                                : AppColors.text,
                          ),
                        ),
                      ),
                      const Icon(
                        Icons.expand_more_rounded,
                        color: AppColors.textSecondary,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  _submitted && province == null
                      ? l10n.errorProvince
                      : province == null
                      ? ''
                      : _regionHelper(l10n, province.region),
                  style: t.bodySmall?.copyWith(
                    color: _submitted && province == null
                        ? AppColors.danger
                        : AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  l10n.profileExperience,
                  style: t.labelLarge?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: [
                    for (final e in Experience.values)
                      TagChip(
                        label: _expLabel(l10n, e),
                        selected: _experience == e,
                        onTap: () => setState(() => _experience = e),
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  l10n.profileLanguage,
                  style: t.labelLarge?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: AppSpacing.sm,
                  children: [
                    TagChip(
                      key: const Key('lang-vi'),
                      label: l10n.langVi,
                      selected: _lang == 'vi',
                      onTap: () {
                        setState(() => _lang = 'vi');
                        ref.read(localeProvider.notifier).set('vi');
                      },
                    ),
                    TagChip(
                      key: const Key('lang-en'),
                      label: l10n.langEn,
                      selected: _lang == 'en',
                      onTap: () {
                        setState(() => _lang = 'en');
                        ref.read(localeProvider.notifier).set('en');
                      },
                    ),
                  ],
                ),
                if (_saveError != null) ...[
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    _saveError!,
                    style: t.bodyMedium?.copyWith(color: AppColors.danger),
                  ),
                ],
                const SizedBox(height: AppSpacing.xl),
                GlowButton(
                  key: const Key('profile-submit'),
                  label: _editing ? l10n.commonSave : l10n.commonContinue,
                  onPressed: _saving ? null : _submit,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _regionHelper(AppLocalizations l10n, VnRegion r) => switch (r) {
    VnRegion.south => l10n.regionHelperSouth,
    VnRegion.north => l10n.regionHelperNorth,
    VnRegion.central => l10n.regionHelperCentral,
  };

  String _expLabel(AppLocalizations l10n, Experience e) => switch (e) {
    Experience.beginner => l10n.expNew,
    Experience.intermediate => l10n.expMid,
    Experience.pro => l10n.expPro,
  };
}

class _ProvinceSheet extends StatefulWidget {
  const _ProvinceSheet({required this.hint});
  final String hint;

  @override
  State<_ProvinceSheet> createState() => _ProvinceSheetState();
}

class _ProvinceSheetState extends State<_ProvinceSheet> {
  String _q = '';

  @override
  Widget build(BuildContext context) {
    final q = viNormalize(_q.trim());
    final items = kProvinces
        .where((p) => q.isEmpty || viNormalize(p.name).contains(q))
        .toList();
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.7,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: GlassTextField(
                  hint: widget.hint,
                  prefixIcon: Icons.search_rounded,
                  onChanged: (v) => setState(() => _q = v),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: items.length,
                  itemBuilder: (_, i) => ListTile(
                    title: Text(items[i].name),
                    onTap: () => Navigator.of(context).pop(items[i]),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
