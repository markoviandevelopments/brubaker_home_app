import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import '../data/visit_data.dart'; // Separate data

class VisitScreen extends StatefulWidget {
  const VisitScreen({super.key});

  @override
  _VisitScreenState createState() => _VisitScreenState();
}

class _VisitScreenState extends State<VisitScreen> {
  String _priceFilter = 'All';
  String _hoursFilter = 'All';
  String _distanceFilter = 'All';

  List<Map<String, dynamic>> get _filteredAttractions {
    return attractions.where((a) {
      bool priceMatch =
          _priceFilter == 'All' || a['price'].contains(_priceFilter);
      bool hoursMatch =
          _hoursFilter == 'All' || a['hours'].contains(_hoursFilter);
      bool distanceMatch =
          _distanceFilter == 'All' || a['distance'] == _distanceFilter;
      return priceMatch && hoursMatch && distanceMatch;
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
              Text('Distance: ${item['distance']}'),
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
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildDropdown(
                'Price',
                ['All', 'Free', '\$', '\$\$', 'Varies'],
                _priceFilter,
                (v) => setState(() => _priceFilter = v!),
              ),
              _buildDropdown(
                'Hours',
                ['All', 'All Day', 'Daytime', 'Afternoon/Evening', 'Seasonal'],
                _hoursFilter,
                (v) => setState(() => _hoursFilter = v!),
              ),
              _buildDropdown(
                'Distance',
                ['All', 'Near', 'Mid', 'Far'],
                _distanceFilter,
                (v) => setState(() => _distanceFilter = v!),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: _filteredAttractions.length,
            itemBuilder: (context, index) {
              final a = _filteredAttractions[index];
              return Card(
                color: Colors.white,
                elevation: 2,
                child: ListTile(
                  leading: a['image'] != null
                      ? Image.asset(
                          a['image'],
                          width: 50,
                          height: 50,
                          fit: BoxFit.cover,
                        )
                      : Icon(
                          Icons.place,
                          color: Theme.of(context).primaryColor,
                        ), // Brown accent
                  title: Text(a['name']),
                  subtitle: Text(
                    '${a['type']} • ${a['price']} • ${a['hours']} • ${a['distance']}',
                  ),
                  trailing: RatingBarIndicator(
                    rating: a['rating'],
                    itemBuilder: (context, _) => Icon(
                      Icons.star,
                      color: Theme.of(context).colorScheme.secondary,
                    ), // Red stars
                    itemCount: 5,
                    itemSize: 20.0,
                  ),
                  onTap: () => _showDetailsDialog(context, a),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDropdown(
    String label,
    List<String> items,
    String value,
    ValueChanged<String?> onChanged,
  ) {
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
