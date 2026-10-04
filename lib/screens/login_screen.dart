// Login screen where the user connects by entering a Canvas access token, with step-by-step instructions.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../components/error_dialog.dart';
import '../services/canvas_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final CanvasService _canvasService = CanvasService();
  final TextEditingController _tokenController = TextEditingController();
  bool _isLoading = false;
  bool _obscureToken = true;

  @override
  void initState() {
    super.initState();
    _checkExistingSession();
  }

  Future<void> _checkExistingSession() async {
    final prefs = await SharedPreferences.getInstance();
    final savedToken = prefs.getString('canvas_api_token');
    if (savedToken != null && savedToken.isNotEmpty && mounted) {
      context.go('/dashboard');
    }
  }

  @override
  void dispose() {
    _tokenController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    final token = _tokenController.text.trim();
    if (token.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please paste your Canvas access token.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    final isValid = await _canvasService.verifyAndSaveToken(token);

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (isValid) {
      context.go('/dashboard');
    } else {
      showDialog(
        context: context,
        builder: (context) => ErrorDialog(
          title: "Authentication failed",
          message: "Could not authorize with Canvas. Check your internet connection and ensure your token is copied correctly from your HAU account settings.",
          onDismiss: () => Navigator.of(context).pop(),
        ),
      );
    }
  }

  void _showInstructionsSheet(ThemeData theme) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      constraints: const BoxConstraints(maxWidth: 560),
      backgroundColor: theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.85,
          maxChildSize: 0.95,
          minChildSize: 0.5,
          builder: (context, scrollController) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              child: ListView(
                controller: scrollController,
                children: [
                  Center(
                    child: Container(
                      height: 4,
                      width: 40,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Get Your Canvas Token',
                        style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Canvas lets you create an official access token to connect external apps to your courses without sharing your university password.',
                    style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.secondary),
                  ),
                  const SizedBox(height: 20),

                  _buildStep(
                    theme: theme,
                    stepNumber: 1,
                    title: 'Open Canvas in your browser',
                    description: 'Log into your Holy Angel University Canvas account via your mobile or desktop browser.',
                    actionLabel: 'Open hau.instructure.com',
                    onAction: () async {
                      final url = Uri.parse('https://hau.instructure.com');
                      if (await canLaunchUrl(url)) await launchUrl(url, mode: LaunchMode.externalApplication);
                    },
                  ),
                  _buildStep(
                    theme: theme,
                    stepNumber: 2,
                    title: 'Go to Account Settings',
                    description: 'Tap on "Account" (your profile icon on the left navigation sidebar) and select "Settings".',
                  ),
                  _buildStep(
                    theme: theme,
                    stepNumber: 3,
                    title: 'Find Approved Integrations',
                    description: 'Scroll down towards the bottom of the page until you find the "Approved Integrations" section.',
                  ),
                  _buildStep(
                    theme: theme,
                    stepNumber: 4,
                    title: 'Create a New Token',
                    description: 'Click the "+ New Access Token" button. In the Purpose field, type "Velo" and set an expiration date, such as the end of the semester.',
                  ),
                  _buildStep(
                    theme: theme,
                    stepNumber: 5,
                    title: 'Copy the Token Immediately',
                    description: 'Tap "Generate Token". Canvas will show your token once. Copy the entire string right away.',
                    isWarning: true,
                  ),
                  _buildStep(
                    theme: theme,
                    stepNumber: 6,
                    title: 'Paste and Connect',
                    description: 'Switch back to Velo, paste the token into the field, and tap "Connect to Canvas".',
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildStep({
    required ThemeData theme,
    required int stepNumber,
    required String title,
    required String description,
    String? actionLabel,
    VoidCallback? onAction,
    bool isWarning = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 28,
            width: 28,
            decoration: BoxDecoration(
              color: isWarning ? theme.colorScheme.error : theme.colorScheme.primary,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              '$stepNumber',
              style: TextStyle(
                color: isWarning ? theme.colorScheme.onError : theme.colorScheme.onPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isWarning ? theme.colorScheme.error : theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.secondary,
                    height: 1.4,
                  ),
                ),
                if (actionLabel != null && onAction != null) ...[
                  const SizedBox(height: 6),
                  InkWell(
                    onTap: onAction,
                    child: Text(
                      actionLabel,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.bold,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 600;

            return Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 440),
                  child: Container(
                    padding: isWide ? const EdgeInsets.all(32) : EdgeInsets.zero,
                    decoration: isWide
                        ? BoxDecoration(
                            color: theme.colorScheme.surface,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: theme.colorScheme.onSurface.withValues(alpha: 0.08)),
                          )
                        : null,
                    child: _buildForm(theme, onCard: isWide),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildForm(ThemeData theme, {required bool onCard}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          height: 64,
          width: 64,
          decoration: BoxDecoration(
            color: theme.colorScheme.primary,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(Icons.school, size: 32, color: theme.colorScheme.onPrimary),
        ),
        const SizedBox(height: 20),
        Text(
          'Velo',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Your Holy Angel coursework, planned for you.',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.secondary,
          ),
        ),
        const SizedBox(height: 36),

        TextField(
          controller: _tokenController,
          obscureText: _obscureToken,
          decoration: InputDecoration(
            hintText: 'Paste Canvas API Token...',
            hintStyle: TextStyle(color: theme.colorScheme.secondary, fontSize: 14),
            filled: true,
            fillColor: onCard ? theme.scaffoldBackgroundColor : theme.colorScheme.surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: theme.colorScheme.onSurface.withValues(alpha: 0.1)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: theme.colorScheme.onSurface.withValues(alpha: 0.1)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: theme.colorScheme.primary),
            ),
            prefixIcon: Icon(Icons.vpn_key_outlined, color: theme.colorScheme.secondary, size: 20),
            suffixIcon: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(_obscureToken ? Icons.visibility_off : Icons.visibility, size: 20),
                  color: theme.colorScheme.secondary,
                  onPressed: () => setState(() => _obscureToken = !_obscureToken),
                ),
                IconButton(
                  icon: const Icon(Icons.paste, size: 20),
                  color: theme.colorScheme.secondary,
                  tooltip: 'Paste from clipboard',
                  onPressed: () async {
                    final data = await Clipboard.getData(Clipboard.kTextPlain);
                    if (data?.text != null) {
                      _tokenController.text = data!.text!.trim();
                    }
                  },
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        SizedBox(
          width: double.infinity,
          child: FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: theme.colorScheme.onPrimary,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: _isLoading ? null : _handleLogin,
            child: _isLoading
                ? SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: theme.colorScheme.onPrimary),
                  )
                : const Text(
                    'Connect to Canvas',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
          ),
        ),
        const SizedBox(height: 12),

        TextButton.icon(
          onPressed: () => _showInstructionsSheet(theme),
          icon: Icon(Icons.help_outline, size: 16, color: theme.colorScheme.secondary),
          label: Text(
            'How do I find my access token?',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.secondary,
              fontWeight: FontWeight.w600,
              decoration: TextDecoration.underline,
            ),
          ),
        ),
        const SizedBox(height: 12),

        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.shield_outlined, size: 14, color: theme.colorScheme.secondary),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                'Stored locally on this device · we never store your password',
                textAlign: TextAlign.center,
                style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.secondary),
              ),
            ),
          ],
        ),
      ],
    );
  }
}