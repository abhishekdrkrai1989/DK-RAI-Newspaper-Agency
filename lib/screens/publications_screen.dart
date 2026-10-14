import 'package:flutter/material.dart';
import '../models/publication.dart';
import '../providers/delivery_provider.dart';

class PublicationsScreen extends StatelessWidget {
  final DeliveryProvider provider;

  const PublicationsScreen({super.key, required this.provider});

  void _showAddPublicationDialog(BuildContext context, [Publication? existing]) {
    final s = provider.strings;
    final nameEnCtrl = TextEditingController(text: existing?.nameEn ?? '');
    final nameHiCtrl = TextEditingController(text: existing?.nameHi ?? '');
    final weekdayPriceCtrl = TextEditingController(
      text: (existing?.weekdayPrice ?? 5.0).toStringAsFixed(0),
    );
    final weekendPriceCtrl = TextEditingController(
      text: (existing?.weekendPrice ?? 7.0).toStringAsFixed(0),
    );
    PublicationType type = existing?.type ?? PublicationType.newspaper;
    DeliveryFrequency freq =
        existing?.defaultFrequency ?? DeliveryFrequency.daily;

    showDialog<void>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setState) {
            return AlertDialog(
              title: Text(
                existing == null
                    ? s.tr('Add Newspaper / Magazine', 'नया अखबार / पत्रिका जोड़ें')
                    : s.tr('Edit Publication', 'अखबार विवरण बदलें'),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameEnCtrl,
                      decoration: InputDecoration(
                        labelText: s.tr('Name (English)', 'नाम (अंग्रेजी में)'),
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: nameHiCtrl,
                      decoration: InputDecoration(
                        labelText: s.tr('Name (Hindi)', 'नाम (हिंदी में)'),
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<PublicationType>(
                      initialValue: type,
                      decoration: InputDecoration(
                        labelText: s.tr('Type', 'प्रकार'),
                        border: const OutlineInputBorder(),
                      ),
                      items: [
                        DropdownMenuItem(
                          value: PublicationType.newspaper,
                          child: Text(s.newspaperLabel),
                        ),
                        DropdownMenuItem(
                          value: PublicationType.magazine,
                          child: Text(s.magazineLabel),
                        ),
                      ],
                      onChanged: (v) {
                        if (v != null) setState(() => type = v);
                      },
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<DeliveryFrequency>(
                      initialValue: freq,
                      decoration: InputDecoration(
                        labelText: s.variantLabel,
                        border: const OutlineInputBorder(),
                      ),
                      items: DeliveryFrequency.values.map((f) {
                        return DropdownMenuItem(
                          value: f,
                          child: Text(f.label(s)),
                        );
                      }).toList(),
                      onChanged: (v) {
                        if (v != null) setState(() => freq = v);
                      },
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: weekdayPriceCtrl,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: s.tr('Weekday ₹', 'सामान्य दिन ₹'),
                              border: const OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: weekendPriceCtrl,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: s.tr('Weekend ₹', 'वीकेंड ₹'),
                              border: const OutlineInputBorder(),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: Text(s.cancel),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E3A8A),
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () async {
                    final en = nameEnCtrl.text.trim();
                    final hi = nameHiCtrl.text.trim();
                    if (en.isEmpty && hi.isEmpty) return;

                    final pub = Publication(
                      id: existing?.id ??
                          'pub_${DateTime.now().millisecondsSinceEpoch}',
                      nameEn: en.isNotEmpty ? en : hi,
                      nameHi: hi.isNotEmpty ? hi : en,
                      type: type,
                      defaultFrequency: freq,
                      weekdayPrice:
                          double.tryParse(weekdayPriceCtrl.text) ?? 5.0,
                      weekendPrice:
                          double.tryParse(weekendPriceCtrl.text) ?? 7.0,
                    );
                    await provider.savePublication(pub);
                    if (ctx.mounted) Navigator.of(ctx).pop();
                  },
                  child: Text(s.confirm),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: provider,
      builder: (context, _) {
        final s = provider.strings;
        final pubs = provider.publications;

        return Scaffold(
          appBar: AppBar(
            title: Text(s.managePublications),
            backgroundColor: const Color(0xFF1E3A8A),
            foregroundColor: Colors.white,
          ),
          floatingActionButton: FloatingActionButton.extended(
            backgroundColor: const Color(0xFF1E3A8A),
            foregroundColor: Colors.white,
            icon: const Icon(Icons.add),
            label: Text(s.tr('Add Paper', 'अखबार जोड़ें')),
            onPressed: () => _showAddPublicationDialog(context),
          ),
          body: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: pubs.length,
            itemBuilder: (context, index) {
              final pub = pubs[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 10),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: pub.type == PublicationType.magazine
                        ? Colors.purple.shade50
                        : Colors.blue.shade50,
                    child: Icon(
                      pub.type == PublicationType.magazine
                          ? Icons.menu_book
                          : Icons.newspaper,
                      color: pub.type == PublicationType.magazine
                          ? Colors.purple.shade700
                          : const Color(0xFF1E3A8A),
                    ),
                  ),
                  title: Text(
                    '${pub.nameEn} (${pub.nameHi})',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    '${pub.type == PublicationType.magazine ? s.magazineLabel : s.newspaperLabel} • ${pub.defaultFrequency.shortLabel(s)} • ₹${pub.weekdayPrice.toStringAsFixed(0)} / ₹${pub.weekendPrice.toStringAsFixed(0)}',
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.edit_outlined),
                    onPressed: () => _showAddPublicationDialog(context, pub),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
