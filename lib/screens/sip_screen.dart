import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import '../data/sip_data.dart'; // Separate data

class SipScreen extends StatefulWidget {
  const SipScreen({super.key});

  @override
  _SipScreenState createState() => _SipScreenState();
}

class _SipScreenState extends State<SipScreen> {
  String _priceFilter = 'All';
  String _hoursFilter = 'All';
  String _formalityFilter = 'All';

  List<Map<String, dynamic>> get _filteredCoffeeShops {
    return coffeeShops.where((c) {
      bool priceMatch =
          _priceFilter == 'All' || c['price'].contains(_priceFilter);
      bool hoursMatch =
          _hoursFilter == 'All' || c['hours'].contains(_hoursFilter);
      bool formalityMatch =
          _formalityFilter == 'All' || c['formality'] == _formalityFilter;
      return priceMatch && hoursMatch && formalityMatch;
    }).toList();
  }

  void _showDetailsDialog(BuildContext context, Map<String, dynamic> item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        title: Text(item['name']),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (item['image'] != null)
                Image.asset(item['image'], height: 100),
              Text('Rating: ${item['rating']} ⭐'),
              Text('Price: ${item['price']}'),
              Text('Hours: ${item['hours']}'),
              Text('Formality: ${item['formality']}'),
              Text('Address: ${item['address']}'),
              const SizedBox(height: 8),
              Text(item['description']),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sip: Coffee in Katy')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildDropdown(
                  'Price',
                  ['All', '\$', '\$\$', '\$\$\$', '\$\$\$\$'],
                  _priceFilter,
                  (v) => setState(() => _priceFilter = v!),
                ),
                _buildDropdown(
                  'Hours',
                  ['All', 'Breakfast', 'Lunch', 'Dinner', 'All Day'],
                  _hoursFilter,
                  (v) => setState(() => _hoursFilter = v!),
                ),
                _buildDropdown(
                  'Formality',
                  ['All', 'Casual', 'Semi-formal'],
                  _formalityFilter,
                  (v) => setState(() => _formalityFilter = v!),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _filteredCoffeeShops.length,
              itemBuilder: (context, index) {
                final c = _filteredCoffeeShops[index];
                return Card(
                  color: Colors.white,
                  elevation: 2,
                  child: ListTile(
                    leading: c['image'] != null
                        ? Image.asset(
                            c['image'],
                            width: 50,
                            height: 50,
                            fit: BoxFit.cover,
                          )
                        : Icon(
                            Icons.coffee,
                            color: Theme.of(context).primaryColor,
                          ), // Brown accent
                    title: Text(c['name']),
                    subtitle: Text(
                      '${c['type']} • ${c['price']} • ${c['hours']} • ${c['formality']}',
                    ),
                    trailing: RatingBarIndicator(
                      rating: c['rating'],
                      itemBuilder: (context, _) => Icon(
                        Icons.star,
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                      itemCount: 5,
                      itemSize: 20.0,
                    ),
                    onTap: () => _showDetailsDialog(context, c),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown(
    String label,
    List<String> items,
    String value,
    ValueChanged<String?> onChanged,
  ) {
    // Unchanged from Eat
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 12)),
        DropdownButton<String>(
          value: value,
          onChanged: onChanged,
          items: items
              .map(
                (String v) =>
                    DropdownMenuItem<String>(value: v, child: Text(v)),
              )
              .toList(),
        ),
      ],
    );
  }
}
