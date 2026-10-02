import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:business_sahaj_erp/data/local/collections/party_collection.dart';
import 'package:business_sahaj_erp/data/local/collections/invoice_collection.dart';
import 'package:business_sahaj_erp/data/local/collections/purchase_collection.dart';
import 'package:business_sahaj_erp/data/local/collections/transaction_collection.dart';
import 'package:business_sahaj_erp/domain/repositories/party_repository.dart';
import 'package:business_sahaj_erp/data/repositories/party_repository_impl.dart';
import 'package:business_sahaj_erp/data/local/party_local_data_source.dart';
import 'package:business_sahaj_erp/data/remote/party_remote_data_source.dart';
import 'package:business_sahaj_erp/presentation/providers/core_providers.dart';
import 'package:isar/isar.dart';

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
  final isar = ref.watch(isarProvider);
  final local = ref.watch(partyLocalDataSourceProvider);
  final remote = ref.watch(partyRemoteDataSourceProvider);
  return PartyRepositoryImpl(isar, local, remote);
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

// State notifier managing nearby party queries
class NearbyPartyNotifier extends StateNotifier<AsyncValue<List<NearbyParty>>> {
  final PartyRepository _repo;

  NearbyPartyNotifier(this._repo) : super(const AsyncValue.data([]));

  Future<void> findNearbyParties() async {
    state = const AsyncValue.data([]);
  }
}

final nearbyPartyProvider = StateNotifierProvider<NearbyPartyNotifier, AsyncValue<List<NearbyParty>>>((ref) {
  final repo = ref.watch(partyRepositoryProvider);
  return NearbyPartyNotifier(repo);
});

// Provider that returns all active parties
final partiesListProvider = FutureProvider<List<Party>>((ref) async {
  final repo = ref.watch(partyRepositoryProvider);
  return repo.getAll();
});

// Pre-computed party balance cache — built ONCE, used by all party cards instantly
final partyBalanceCacheProvider = FutureProvider<Map<String, double>>((ref) async {
  final isar = ref.watch(isarProvider);
  final Map<String, double> balanceMap = {};

  final parties = await isar.partys.filter().isDeletedEqualTo(false).findAll();
  final invoices = await isar.invoices.filter().isDeletedEqualTo(false).findAll();
  final purchases = await isar.purchases.filter().isDeletedEqualTo(false).findAll();
  final txns = await isar.transactions.filter().isDeletedEqualTo(false).findAll();

  for (var party in parties) {
    final partyUuid = party.uuid;
    final partyId = party.id;
    final partyNameLower = party.partyName?.trim().toLowerCase() ?? '';

    double bal = party.openingBalance ?? 0.0;
    if (party.balanceType == 'Cr') {
      bal = -bal.abs();
    } else {
      bal = bal.abs();
    }

    for (var inv in invoices) {
      final invNameLower = inv.partyName?.trim().toLowerCase() ?? '';
      final matches = (partyUuid != null && partyUuid.isNotEmpty && inv.party.value?.uuid == partyUuid) ||
                      (partyId > 0 && inv.partyId == partyId) ||
                      (partyNameLower.isNotEmpty && invNameLower == partyNameLower);
      if (matches && inv.paymentStatus != 'Cancelled') {
        final pending = inv.pendingAmount ?? ((inv.grandTotal ?? 0.0) - (inv.paidAmount ?? 0.0));
        bal += pending > 0 ? pending : 0.0;
      }
    }

    for (var pur in purchases) {
      final purNameLower = pur.partyName?.trim().toLowerCase() ?? '';
      final matches = (partyUuid != null && partyUuid.isNotEmpty && pur.party.value?.uuid == partyUuid) ||
                      (partyId > 0 && pur.partyId == partyId) ||
                      (partyNameLower.isNotEmpty && purNameLower == partyNameLower);
      if (matches && pur.paymentStatus != 'Cancelled') {
        final pending = pur.pendingAmount ?? ((pur.grandTotal ?? 0.0) - (pur.paidAmount ?? 0.0));
        bal -= pending > 0 ? pending : 0.0;
      }
    }

    for (var txn in txns) {
      final amt = txn.amount ?? 0.0;
      final type = txn.transactionType;
      final matchesSource = (partyUuid != null && partyUuid.isNotEmpty && txn.partyUuid == partyUuid) ||
                            (txn.partyUuid == null && partyNameLower.isNotEmpty && txn.partyName?.trim().toLowerCase() == partyNameLower);
      final matchesTarget = (partyUuid != null && partyUuid.isNotEmpty && txn.targetPartyUuid == partyUuid);
      final isLinkedToBill = txn.linkedBillUuid != null && txn.linkedBillUuid!.isNotEmpty;

      if (type == 'Receipt' || type == 'Other Income') {
        if (matchesSource && !isLinkedToBill) bal -= amt;
      } else if (type == 'Payment' || type == 'Expense') {
        if (matchesSource && !isLinkedToBill) bal += amt;
      } else if (type == 'Credit Note') {
        if (matchesSource) bal -= amt;
      } else if (type == 'Debit Note') {
        if (matchesSource) bal += amt;
      } else if (['Transfer', 'Bank Transfer', 'Cash Adjustment', 'Party Transfer', 'Party to Party Transfer'].contains(type)) {
        if (matchesSource) bal -= amt;
        else if (matchesTarget) bal += amt;
      }
    }

    if (party.uuid != null && party.uuid!.isNotEmpty) {
      balanceMap[party.uuid!] = bal;
    }
    if (partyNameLower.isNotEmpty) {
      balanceMap[partyNameLower] = bal;
      balanceMap['supp_$partyNameLower'] = bal;
    }
  }

  return balanceMap;
});

final quickActionPrefillPartyProvider = StateProvider<Party?>((ref) => null);
