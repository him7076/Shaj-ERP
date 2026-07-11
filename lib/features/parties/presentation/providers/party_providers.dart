import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:business_sahaj_erp/data/local/collections/party_collection.dart';
import 'package:business_sahaj_erp/domain/repositories/party_repository.dart';
import 'package:business_sahaj_erp/data/repositories/party_repository_impl.dart';
import 'package:business_sahaj_erp/data/local/party_local_data_source.dart';
import 'package:business_sahaj_erp/data/remote/party_remote_data_source.dart';
import 'package:business_sahaj_erp/presentation/providers/core_providers.dart';
import 'package:business_sahaj_erp/core/services/gps_service.dart';
import 'package:business_sahaj_erp/core/utils/distance_calculator.dart';

// Local DataSource Provider
final partyLocalDataSourceProvider = Provider<PartyLocalDataSource>((ref) {
  final dbService = ref.watch(databaseServiceProvider);
  return PartyLocalDataSource(dbService);
});

// Remote DataSource Provider
final partyRemoteDataSourceProvider = Provider<PartyRemoteDataSource>((ref) {
  final firebaseService = ref.watch(firebaseServiceProvider);
  return PartyRemoteDataSource(firebaseService);
});

// Overriding global PartyRepository Provider
final partyRepositoryProvider = Provider<PartyRepository>((ref) {
  final dbService = ref.watch(databaseServiceProvider);
  final local = ref.watch(partyLocalDataSourceProvider);
  final remote = ref.watch(partyRemoteDataSourceProvider);
  return PartyRepositoryImpl(dbService.isar, local, remote);
});

// GPS Service Provider
final gpsServiceProvider = Provider<GpsService>((ref) {
  return GpsService();
});

// Search & Filter State structure
class PartySearchState {
  final String query;
  final String? filterType;
  final String? filterCity;
  final String? filterState;
  final String sortBy; // 'Name', 'Recent', 'Outstanding', 'City'

  PartySearchState({
    this.query = '',
    this.filterType,
    this.filterCity,
    this.filterState,
    this.sortBy = 'Name',
  });

  PartySearchState copyWith({
    String? query,
    String? filterType,
    String? filterCity,
    String? filterState,
    String? sortBy,
  }) {
    return PartySearchState(
      query: query ?? this.query,
      filterType: filterType == 'All' ? null : (filterType ?? this.filterType),
      filterCity: filterCity == 'All' ? null : (filterCity ?? this.filterCity),
      filterState: filterState == 'All' ? null : (filterState ?? this.filterState),
      sortBy: sortBy ?? this.sortBy,
    );
  }
}

// Search state notifier provider
class PartySearchNotifier extends StateNotifier<PartySearchState> {
  PartySearchNotifier() : super(PartySearchState());

  void setQuery(String q) => state = state.copyWith(query: q);
  void setFilterType(String? t) => state = state.copyWith(filterType: t ?? 'All');
  void setFilterCity(String? c) => state = state.copyWith(filterCity: c ?? 'All');
  void setFilterState(String? s) => state = state.copyWith(filterState: s ?? 'All');
  void setSortBy(String s) => state = state.copyWith(sortBy: s);
  
  void reset() => state = PartySearchState();
}

final partySearchProvider = StateNotifierProvider<PartySearchNotifier, PartySearchState>((ref) {
  return PartySearchNotifier();
});

// Computed provider returning filtered and sorted party list
final filteredPartiesProvider = FutureProvider<List<Party>>((ref) async {
  final repo = ref.watch(partyRepositoryProvider);
  final searchState = ref.watch(partySearchProvider);

  // 1. Fetch matches from local database (offline fast search on indexes)
  List<Party> list = await repo.searchParties(searchState.query);

  // 2. Apply filters (type, city, state)
  if (searchState.filterType != null) {
    list = list.where((p) => p.partyType == searchState.filterType).toList();
  }
  if (searchState.filterCity != null) {
    list = list.where((p) => p.city?.toLowerCase() == searchState.filterCity!.toLowerCase()).toList();
  }
  if (searchState.filterState != null) {
    list = list.where((p) => p.state?.toLowerCase() == searchState.filterState!.toLowerCase()).toList();
  }

  // 3. Apply sorting keys
  switch (searchState.sortBy) {
    case 'Recent':
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      break;
    case 'Outstanding':
      // Sort Outstanding balance descending (in demo we utilize openingBalance)
      list.sort((a, b) => (b.openingBalance ?? 0.0).compareTo(a.openingBalance ?? 0.0));
      break;
    case 'City':
      list.sort((a, b) => (a.city ?? '').compareTo(b.city ?? ''));
      break;
    case 'Name':
    default:
      list.sort((a, b) => (a.partyName ?? '').compareTo(b.partyName ?? ''));
      break;
  }

  return list;
});

// Struct mapping nearby party queries
class NearbyParty {
  final Party party;
  final double distanceInMeters;

  NearbyParty({required this.party, required this.distanceInMeters});
}

// State notifier managing GPS position and distance matrix mapping
class NearbyPartyNotifier extends StateNotifier<AsyncValue<List<NearbyParty>>> {
  final PartyRepository _repo;
  final GpsService _gpsService;

  NearbyPartyNotifier(this._repo, this._gpsService) : super(const AsyncValue.loading());

  Future<void> findNearbyParties() async {
    state = const AsyncValue.loading();
    try {
      // 1. Capture user GPS location coordinates
      final position = await _gpsService.getCurrentLocation();
      
      // 2. Fetch all active parties
      final allParties = await _repo.getAll();
      
      final List<NearbyParty> nearbyList = [];
      for (var party in allParties) {
        if (party.latitude != null && party.longitude != null) {
          // 3. Compute offline Haversine distance
          final distance = DistanceCalculator.calculateDistanceInMeters(
            position.latitude,
            position.longitude,
            party.latitude!,
            party.longitude!,
          );
          nearbyList.add(NearbyParty(party: party, distanceInMeters: distance));
        }
      }

      // 4. Sort ascending (closest first)
      nearbyList.sort((a, b) => a.distanceInMeters.compareTo(b.distanceInMeters));
      
      state = AsyncValue.data(nearbyList);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
}

final nearbyPartyProvider = StateNotifierProvider<NearbyPartyNotifier, AsyncValue<List<NearbyParty>>>((ref) {
  final repo = ref.watch(partyRepositoryProvider);
  final gps = ref.watch(gpsServiceProvider);
  return NearbyPartyNotifier(repo, gps);
});

// Provider that returns all active parties
final partiesListProvider = FutureProvider<List<Party>>((ref) async {
  final repo = ref.watch(partyRepositoryProvider);
  return repo.getAll();
});
