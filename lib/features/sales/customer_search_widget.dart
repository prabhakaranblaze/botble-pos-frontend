import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/models/customer.dart';
import '../../shared/constants/app_constants.dart';

class CustomerSearchWidget extends StatefulWidget {
  final Customer? selectedCustomer;
  final Function(Customer) onCustomerSelected;
  final VoidCallback onCustomerRemoved;
  final VoidCallback onAddNewCustomer;
  final Future<List<Customer>> Function(String) onSearch;

  const CustomerSearchWidget({
    super.key,
    this.selectedCustomer,
    required this.onCustomerSelected,
    required this.onCustomerRemoved,
    required this.onAddNewCustomer,
    required this.onSearch,
  });

  @override
  State<CustomerSearchWidget> createState() => _CustomerSearchWidgetState();
}

class _CustomerSearchWidgetState extends State<CustomerSearchWidget> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  List<Customer> _searchResults = [];
  bool _isSearching = false;
  bool _showDropdown = false;

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  Future<void> _handleSearch(String query) async {
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _showDropdown = false;
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _showDropdown = true;
    });

    try {
      final results = await widget.onSearch(query);
      setState(() {
        _searchResults = results;
        _isSearching = false;
      });
    } catch (e) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
    }
  }

  void _selectCustomer(Customer customer) {
    widget.onCustomerSelected(customer);
    _searchController.clear();
    setState(() {
      _showDropdown = false;
      _searchResults = [];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(Icons.person_outline, color: AppColors.primary),
                const SizedBox(width: 8),
                const Text(
                  'Customer',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Search Input
            if (widget.selectedCustomer == null)
              Column(
                children: [
                  TextField(
                    controller: _searchController,
                    focusNode: _searchFocusNode,
                    decoration: InputDecoration(
                      hintText: 'Search customer...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                                setState(() {
                                  _searchResults = [];
                                  _showDropdown = false;
                                });
                              },
                            )
                          : null,
                    ),
                    onChanged: (value) {
                      _handleSearch(value);
                      setState(() {});
                    },
                  ),

                  // Search Results Dropdown
                  if (_showDropdown)
                    Container(
                      margin: const EdgeInsets.only(top: 8),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.border),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      constraints: const BoxConstraints(maxHeight: 250),
                      child: _isSearching
                          ? const Center(
                              child: Padding(
                                padding: EdgeInsets.all(16),
                                child: CircularProgressIndicator(),
                              ),
                            )
                          : _searchResults.isEmpty
                              ? Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Text(
                                    'No customers found',
                                    style: TextStyle(
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                )
                              : ListView.builder(
                                  shrinkWrap: true,
                                  itemCount: _searchResults.length,
                                  itemBuilder: (context, index) {
                                    final customer = _searchResults[index];
                                    return ListTile(
                                      leading: CircleAvatar(
                                        backgroundColor:
                                            AppColors.primary.withOpacity(0.1),
                                        child: Icon(
                                          Icons.person,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                      title: Text(
                                        '${customer.name} (${customer.phone ?? 'No phone'})',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      subtitle: customer.email != null
                                          ? Text(customer.email!)
                                          : null,
                                      onTap: () => _selectCustomer(customer),
                                    );
                                  },
                                ),
                    ),
                ],
              ),

            // Selected Customer Display
            if (widget.selectedCustomer != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppColors.primary.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: AppColors.primary.withOpacity(0.2),
                      child: Icon(
                        Icons.person,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${widget.selectedCustomer!.name} (${widget.selectedCustomer!.phone ?? 'No phone'})',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          if (widget.selectedCustomer!.email != null ||
                              widget.selectedCustomer!.phone != null)
                            Text(
                              [
                                widget.selectedCustomer!.phone,
                                widget.selectedCustomer!.email,
                              ].where((e) => e != null).join(' • '),
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close, color: AppColors.error),
                      onPressed: widget.onCustomerRemoved,
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 12),

            // Add New Customer Button
            Align(
              alignment: Alignment.centerRight,
              child: OutlinedButton.icon(
                onPressed: widget.onAddNewCustomer,
                icon: const Icon(Icons.add),
                label: const Text('Add New Customer'),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: AppColors.primary),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
