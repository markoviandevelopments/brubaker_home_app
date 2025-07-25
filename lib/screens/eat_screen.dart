import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import '../data/eat_data.dart'; // Updated with photos, detailed descriptions, reviews
import '../data/sip_data.dart'; // Updated similarly
import '../services/data_service.dart'; // New: For ratings/reviews persistence (local or backend)

class EatScreen extends StatefulWidget {
  const EatScreen({super.key});

  @override
  _EatScreenState createState() => _EatScreenState();
}

class _EatScreenState extends State<EatScreen> {
  String _priceFilter = 'All';
  String _hoursFilter = 'All';
  String _formalityFilter = 'All';

  final DataService _dataService = DataService(); // Handles ratings/reviews

  List<Map<String, dynamic>> get _filteredRestaurants {
    return restaurants.where((r) {
      bool priceMatch =
          _priceFilter == 'All' || r['price'].contains(_priceFilter);
      bool hoursMatch =
          _hoursFilter == 'All' || r['hours'].contains(_hoursFilter);
      bool formalityMatch =
          _formalityFilter == 'All' || r['formality'] == _formalityFilter;
      return priceMatch && hoursMatch && formalityMatch;
    }).toList();
  }

  void _showDetailsDialog(
    BuildContext context,
    Map<String, dynamic> item,
    bool isCoffee,
  ) {
    double userRating = _dataService.getUserRating(item['name']);
    TextEditingController reviewController = TextEditingController();

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
              if (item['photos']?.isNotEmpty ?? false)
                SizedBox(
                  height: 200,
                  child: PageView.builder(
                    itemCount: item['photos'].length,
                    itemBuilder: (context, i) => Image.asset(
                      item['photos'][i],
                    ), // Use asset for bundled photos
                  ),
                ),
              Text('Average Rating: ${item['rating']} ⭐'),
              RatingBar.builder(
                initialRating: userRating,
                minRating: 1,
                direction: Axis.horizontal,
                allowHalfRating: true,
                itemCount: 5,
                itemSize: 30,
                itemBuilder: (context, _) => Icon(
                  Icons.star,
                  color: Theme.of(context).colorScheme.secondary,
                ),
                onRatingUpdate: (rating) {
                  _dataService.setUserRating(item['name'], rating);
                  setState(() {}); // Refresh if needed
                },
              ),
              Text('Price: ${item['price']}'),
              Text('Hours: ${item['hours']}'),
              Text('Formality: ${item['formality']}'),
              Text('Address: ${item['address']}'),
              const SizedBox(height: 8),
              Text(item['description']), // More detailed/accurate
              const SizedBox(height: 8),
              TextField(
                controller: reviewController,
                decoration: const InputDecoration(
                  hintText: 'Leave a review...',
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  if (reviewController.text.isNotEmpty) {
                    item['reviews'].add(reviewController.text);
                    reviewController.clear();
                    setState(() {}); // Update UI
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                ),
                child: const Text('Submit Review'),
              ),
              if (item['reviews']?.isNotEmpty ?? false) ...[
                const SizedBox(height: 8),
                const Text('Reviews:'),
                ...item['reviews'].map((rev) => Text('- $rev')),
              ],
              if (item['menu_images']?.isNotEmpty ?? false)
                ElevatedButton(
                  onPressed: () =>
                      _showMenuDialog(context, item['menu_images']),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                  ),
                  child: const Text('View Menus'),
                ),
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

  void _showMenuDialog(BuildContext context, List<String> menuImages) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Menus'),
        content: SizedBox(
          height: 300,
          width: double.maxFinite,
          child: ListView.builder(
            itemCount: menuImages.length,
            itemBuilder: (context, i) => Image.asset(menuImages[i]),
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

  void _showSecretPinDialog(BuildContext context) {
    final TextEditingController controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Enter Secret PIN'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          obscureText: true,
          decoration: const InputDecoration(hintText: 'PIN for secret coffee'),
        ),
        actions: [
          TextButton(
            onPressed: () {
              if (controller.text == '1234') {
                Navigator.pop(context);
                _showSipsBottomSheet(context);
              } else {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('Wrong PIN!')));
              }
            },
            child: const Text('Enter'),
          ),
        ],
      ),
    );
  }

  void _showSipsBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.9,
        minChildSize: 0.5,
        builder: (context, scrollController) => ListView.builder(
          controller: scrollController,
          itemCount: coffeeShops.length,
          itemBuilder: (context, index) {
            final c = coffeeShops[index];
            return Card(
              color: Colors.white,
              child: ListTile(
                leading: Icon(
                  Icons.coffee,
                  color: Theme.of(context).primaryColor,
                ),
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
                onTap: () => _showDetailsDialog(context, c, true),
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                  ['All', 'Breakfast', 'Lunch', 'Dinner'],
                  _hoursFilter,
                  (v) => setState(() => _hoursFilter = v!),
                ),
                _buildDropdown(
                  'Formality',
                  ['All', 'Casual', 'Semi-formal', 'Formal'],
                  _formalityFilter,
                  (v) => setState(() => _formalityFilter = v!),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _filteredRestaurants.length,
              itemBuilder: (context, index) {
                final r = _filteredRestaurants[index];
                return Card(
                  color: Colors.white,
                  elevation: 2,
                  child: ListTile(
                    leading: Icon(
                      Icons.restaurant,
                      color: Theme.of(context).primaryColor,
                    ),
                    title: Text(r['name']),
                    subtitle: Text(
                      '${r['cuisine']} • ${r['price']} • ${r['hours']} • ${r['formality']}',
                    ),
                    trailing: RatingBarIndicator(
                      rating: r['rating'],
                      itemBuilder: (context, _) => Icon(
                        Icons.star,
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                      itemCount: 5,
                      itemSize: 20.0,
                    ),
                    onTap: () => _showDetailsDialog(context, r, false),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showSecretPinDialog(context),
        backgroundColor: Theme.of(context).primaryColor,
        child: const Icon(Icons.coffee, color: Colors.white),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
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
