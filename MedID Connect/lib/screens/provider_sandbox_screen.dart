import 'package:flutter/material.dart';

import '../services/api_client.dart';
import '../services/provider_sandbox_service.dart';
import '../theme/app_theme.dart';
import '../widgets/page_header.dart';
import '../widgets/premium_card.dart';
import '../widgets/section_header.dart';

class ProviderSandboxScreen extends StatefulWidget {
  const ProviderSandboxScreen({super.key, this.showBackButton = false});

  static const String route = '/provider-sandbox';

  final bool showBackButton;

  @override
  State<ProviderSandboxScreen> createState() => _ProviderSandboxScreenState();
}

class _ProviderSandboxScreenState extends State<ProviderSandboxScreen> {
  late final ProviderSandboxService _service =
      ProviderSandboxService(ApiClient());
  late final Future<List<Map<String, dynamic>>> _providers = _loadProviders();
  late Future<List<Map<String, dynamic>>> _connected = _loadConnected();
  String? _message;

  Future<List<Map<String, dynamic>>> _loadProviders() async {
    try {
      return await _service.providers();
    } catch (_) {
      return [
        {
          'id': 'hapi',
          'provider_name': 'HAPI FHIR Test Server',
          'provider_type': 'FHIR_R4',
          'notes': 'Offline demo provider',
        },
        {
          'id': 'abdm',
          'provider_name': 'ABDM/ABHA Sandbox',
          'provider_type': 'ABDM',
          'notes': 'Placeholder requiring ABDM registration',
        },
      ];
    }
  }

  Future<List<Map<String, dynamic>>> _loadConnected() async {
    try {
      return await _service.connected();
    } catch (_) {
      return [];
    }
  }

  Future<void> _connect(String providerId) async {
    try {
      await _service.startConnection(providerId);
      final connection = await _service.completeConnection(providerId);
      setState(() {
        _message = 'Connected to ${connection['provider_name']}';
        _connected = _loadConnected();
      });
    } catch (error) {
      setState(() => _message = ApiClient().readableError(error));
    }
  }

  Future<void> _sync(int connectionId) async {
    try {
      final result = await _service.sync(connectionId);
      setState(() => _message = result['message']?.toString());
    } catch (error) {
      setState(() => _message = ApiClient().readableError(error));
    }
  }

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
          child: PageHeader(
            title: 'Connect hospital sandbox',
            subtitle:
                'Mock SMART on FHIR and ABDM-ready provider connections for demo import flows.',
            icon: Icons.hub_rounded,
            showBackButton: widget.showBackButton,
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          sliver: SliverList(
            delegate: SliverChildListDelegate(
              [
                if (_message != null)
                  PremiumCard(
                    color: AppPalette.softBlue,
                    child: Text(
                      _message!,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                const SectionHeader(title: 'Sandbox providers'),
                FutureBuilder<List<Map<String, dynamic>>>(
                  future: _providers,
                  builder: (context, snapshot) {
                    final items = snapshot.data ?? [];
                    return Column(
                      children: items
                          .map(
                            (provider) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: PremiumCard(
                                child: ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  leading: const CircleAvatar(
                                    child: Icon(Icons.local_hospital_rounded),
                                  ),
                                  title: Text(
                                      provider['provider_name']?.toString() ??
                                          'Provider'),
                                  subtitle:
                                      Text(provider['notes']?.toString() ?? ''),
                                  trailing: FilledButton(
                                    onPressed: () =>
                                        _connect(provider['id'].toString()),
                                    child: const Text('Connect'),
                                  ),
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    );
                  },
                ),
                const SectionHeader(title: 'Connected sandboxes'),
                FutureBuilder<List<Map<String, dynamic>>>(
                  future: _connected,
                  builder: (context, snapshot) {
                    final items = snapshot.data ?? [];
                    if (items.isEmpty) {
                      return const PremiumCard(
                        child: Text(
                            'No connected provider yet. Connect HAPI FHIR to import sample data.'),
                      );
                    }
                    return Column(
                      children: items
                          .map(
                            (connection) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: PremiumCard(
                                child: ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  leading: const Icon(Icons.sync_rounded,
                                      color: AppPalette.primary),
                                  title: Text(
                                      connection['provider_name']?.toString() ??
                                          'Connection'),
                                  subtitle:
                                      Text('Status: ${connection['status']}'),
                                  trailing: FilledButton.tonal(
                                    onPressed: () =>
                                        _sync(connection['id'] as int),
                                    child: const Text('Sync'),
                                  ),
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
