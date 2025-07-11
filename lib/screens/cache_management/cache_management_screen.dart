import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nexoeshopee/providers/cache_providers.dart';
import 'package:nexoeshopee/constants.dart';
import 'package:nexoeshopee/size_config.dart';

class CacheManagementScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cacheStats = ref.watch(cacheStatsProvider);
    final cacheManagement = ref.watch(cacheManagementProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('Cache Management'),
        backgroundColor: kPrimaryColor,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(getProportionateScreenWidth(20)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cache Statistics
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Cache Statistics',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Cached Products:'),
                        Text(
                          '${cacheStats.cachedProductsCount}',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Cached Users:'),
                        Text(
                          '${cacheStats.cachedUsersCount}',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 20),

            // Cache Actions
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Cache Actions',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 16),

                    // Clear Product Cache
                    ListTile(
                      leading: Icon(Icons.shopping_bag, color: kPrimaryColor),
                      title: Text('Clear Product Cache'),
                      subtitle: Text('Remove all cached products'),
                      trailing: Icon(Icons.chevron_right),
                      onTap: () => _showClearCacheDialog(
                        context,
                        'Clear Product Cache',
                        'Are you sure you want to clear all cached products?',
                        () => cacheManagement.clearProductCache(),
                      ),
                    ),

                    // Clear User Cache
                    ListTile(
                      leading: Icon(Icons.person, color: kPrimaryColor),
                      title: Text('Clear User Cache'),
                      subtitle: Text('Remove all cached user data'),
                      trailing: Icon(Icons.chevron_right),
                      onTap: () => _showClearCacheDialog(
                        context,
                        'Clear User Cache',
                        'Are you sure you want to clear all cached user data?',
                        () => cacheManagement.clearUserCache(),
                      ),
                    ),

                    // Clear All Cache
                    ListTile(
                      leading: Icon(Icons.delete_sweep, color: Colors.red),
                      title: Text('Clear All Cache'),
                      subtitle: Text('Remove all cached data'),
                      trailing: Icon(Icons.chevron_right),
                      onTap: () => _showClearCacheDialog(
                        context,
                        'Clear All Cache',
                        'Are you sure you want to clear all cached data? This action cannot be undone.',
                        () => cacheManagement.clearAllCache(),
                      ),
                    ),

                    // Cleanup Expired Data
                    ListTile(
                      leading: Icon(Icons.auto_delete, color: kPrimaryColor),
                      title: Text('Cleanup Expired Data'),
                      subtitle: Text('Remove expired cache entries'),
                      trailing: Icon(Icons.chevron_right),
                      onTap: () =>
                          _cleanupExpiredData(context, cacheManagement),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 20),

            // Cache Settings
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Cache Settings',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 16),

                    // Auto cleanup setting
                    Consumer(
                      builder: (context, ref, child) {
                        final autoCleanup =
                            ref
                                .watch(cacheManagementProvider)
                                .getCachedSetting<bool>(
                                  'auto_cleanup',
                                  defaultValue: true,
                                ) ??
                            true;

                        return SwitchListTile(
                          title: Text('Auto Cleanup'),
                          subtitle: Text('Automatically remove expired cache'),
                          value: autoCleanup,
                          onChanged: (value) {
                            ref
                                .read(cacheManagementProvider)
                                .cacheSetting('auto_cleanup', value);
                          },
                        );
                      },
                    ),

                    // Cache size limit setting
                    ListTile(
                      leading: Icon(Icons.storage, color: kPrimaryColor),
                      title: Text('Cache Size Limit'),
                      subtitle: Text('Set maximum cache size'),
                      trailing: Icon(Icons.chevron_right),
                      onTap: () =>
                          _showCacheSizeDialog(context, cacheManagement),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showClearCacheDialog(
    BuildContext context,
    String title,
    String message,
    VoidCallback onConfirm,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              onConfirm();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Cache cleared successfully')),
              );
            },
            child: Text('Clear', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _cleanupExpiredData(
    BuildContext context,
    CacheManagement cacheManagement,
  ) async {
    try {
      await cacheManagement.cleanupExpiredData();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Expired data cleaned up successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error cleaning up expired data: $e')),
      );
    }
  }

  void _showCacheSizeDialog(
    BuildContext context,
    CacheManagement cacheManagement,
  ) {
    final currentLimit =
        cacheManagement.getCachedSetting<int>(
          'cache_size_limit',
          defaultValue: 100,
        ) ??
        100;
    int newLimit = currentLimit;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Cache Size Limit'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Set the maximum number of cached products:'),
            SizedBox(height: 16),
            TextField(
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Max cached products',
                border: OutlineInputBorder(),
              ),
              controller: TextEditingController(text: currentLimit.toString()),
              onChanged: (value) {
                newLimit = int.tryParse(value) ?? currentLimit;
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              cacheManagement.cacheSetting('cache_size_limit', newLimit);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Cache size limit updated')),
              );
            },
            child: Text('Save'),
          ),
        ],
      ),
    );
  }
}
