import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nexoeshopee/services/cache/hive_service.dart';

// Cache initialization provider
final cacheInitializationProvider = FutureProvider<bool>((ref) async {
  try {
    await HiveService.instance.init();
    return true;
  } catch (e) {
    throw Exception('Failed to initialize cache: $e');
  }
});

// Cache health check provider
final cacheHealthProvider = Provider<CacheHealthService>((ref) {
  return CacheHealthService();
});

class CacheHealthService {
  Future<bool> isHealthy() async {
    try {
      final hiveService = HiveService.instance;
      // Try to perform a simple cache operation
      await hiveService.cacheSetting(
        'health_check',
        DateTime.now().millisecondsSinceEpoch,
      );
      final result = hiveService.getCachedSetting<int>('health_check');
      return result != null;
    } catch (e) {
      return false;
    }
  }

  Future<Map<String, dynamic>> getHealthStatus() async {
    try {
      final hiveService = HiveService.instance;
      return {
        'isHealthy': await isHealthy(),
        'cachedProductsCount': hiveService.getCachedProductsCount(),
        'cachedUsersCount': hiveService.getCachedUsersCount(),
        'lastHealthCheck': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      return {
        'isHealthy': false,
        'error': e.toString(),
        'lastHealthCheck': DateTime.now().toIso8601String(),
      };
    }
  }
}

// Auto cleanup provider
final autoCleanupProvider = FutureProvider<void>((ref) async {
  final hiveService = HiveService.instance;
  final autoCleanup =
      hiveService.getCachedSetting<bool>('auto_cleanup', defaultValue: true) ??
      true;

  if (autoCleanup) {
    await hiveService.cleanupExpiredData();
  }
});

// Cache warming provider - preload frequently used data
final cacheWarmingProvider = FutureProvider.family<void, String>((
  ref,
  userId,
) async {
  final hiveService = HiveService.instance;

  // Warm up cache with user's favorite products
  // This would typically be called after user login
  try {
    // You can add logic here to preload user's frequently accessed data
    await hiveService.cacheSetting(
      'cache_warmed_$userId',
      DateTime.now().millisecondsSinceEpoch,
    );
  } catch (e) {
    // Handle cache warming errors silently
  }
});

// Cache performance monitoring
final cachePerformanceProvider =
    StateNotifierProvider<CachePerformanceNotifier, CachePerformanceState>((
      ref,
    ) {
      return CachePerformanceNotifier();
    });

class CachePerformanceState {
  final int hitCount;
  final int missCount;
  final double hitRatio;
  final Map<String, int> operationCounts;

  CachePerformanceState({
    this.hitCount = 0,
    this.missCount = 0,
    this.hitRatio = 0.0,
    this.operationCounts = const {},
  });

  CachePerformanceState copyWith({
    int? hitCount,
    int? missCount,
    double? hitRatio,
    Map<String, int>? operationCounts,
  }) {
    return CachePerformanceState(
      hitCount: hitCount ?? this.hitCount,
      missCount: missCount ?? this.missCount,
      hitRatio: hitRatio ?? this.hitRatio,
      operationCounts: operationCounts ?? this.operationCounts,
    );
  }
}

class CachePerformanceNotifier extends StateNotifier<CachePerformanceState> {
  CachePerformanceNotifier() : super(CachePerformanceState());

  void recordHit() {
    final newHitCount = state.hitCount + 1;
    final newTotal = newHitCount + state.missCount;
    final newHitRatio = newTotal > 0 ? (newHitCount / newTotal) : 0.0;

    state = state.copyWith(hitCount: newHitCount, hitRatio: newHitRatio);
  }

  void recordMiss() {
    final newMissCount = state.missCount + 1;
    final newTotal = state.hitCount + newMissCount;
    final newHitRatio = newTotal > 0 ? (state.hitCount / newTotal) : 0.0;

    state = state.copyWith(missCount: newMissCount, hitRatio: newHitRatio);
  }

  void recordOperation(String operationType) {
    final newOperationCounts = Map<String, int>.from(state.operationCounts);
    newOperationCounts[operationType] =
        (newOperationCounts[operationType] ?? 0) + 1;

    state = state.copyWith(operationCounts: newOperationCounts);
  }

  void reset() {
    state = CachePerformanceState();
  }
}
