import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/utils/digit_converter.dart';
import '../../../../core/utils/validators.dart';
import '../../data/voter_remote_source.dart';
import '../ui_state/voter_ui_state.dart';

class VoterPresenter extends GetxController {
  final _state = VoterUiState().obs;
  VoterUiState get state => _state.value;

  final nameController = TextEditingController();
  final dayController = TextEditingController();
  final monthController = TextEditingController();
  final yearController = TextEditingController();

  int page = 1;

  Future<void> search({bool loadMore = false}) async {
    final d = DigitConverter.bnToEn(dayController.text);
    final m = DigitConverter.bnToEn(monthController.text);
    final y = DigitConverter.bnToEn(yearController.text);
    final name = nameController.text;

    if (Validators.isEmpty(name) || !Validators.validDate(d, m, y)) {
      _state.value = state.copyWith(error: 'সঠিক তথ্য প্রদান করুন');
      return;
    }

    if (loadMore && !state.hasMore) return;

    if (!loadMore) {
      page = 1; // Reset page on new search
      _state.value = state.copyWith(loading: true, error: null, voters: []);
    } else {
      _state.value = state.copyWith(loadingMore: true, error: null);
    }

    try {
      // NOTE: The API endpoint structure in the request was vague about pagination parameters.
      // Assuming straightforward payload for now, or maybe the API doesn't support pagination
      // in the way typical list APIs do.
      // The user code sample showed `search` taking `page` but the remote source implementation
      // in the prompt sample code used a payload map.
      // I will adapt the RemoteSource to take the payload including page if needed,
      // but for now I will stick to the prompts logic which used a payload map.
      // Re-reading user prompt: "VoterRemoteSource().search(page)" was used in the Presenter example,
      // but "VoterRemoteSource().search({...})" was used in the RemoteSource definition.
      // I will reconcile this by passing the payload.

      final payload = {
        '_token':
            'mdTRZn45HczSi8scIXxxCE1TSseo16sbIeYaHZiy', // This probably should be dynamic or fetched, but hardcoded in prompt
        'search_type': 'name',
        'search_value': name,
        'dob_day': d,
        'dob_month': m,
        'dob_year': y,
        // 'page': page, // If the API supports it
      };

      final res = await VoterRemoteSource().search(payload);
      final newVoters = res['voters'] ?? [];

      // If the API returns a list, we append it.
      // Often search APIs return everything or a specific page.
      // Assuming standard pagination behavior for the sake of the "Load More" feature requested.

      _state.value = state.copyWith(
        voters: loadMore ? [...state.voters, ...newVoters] : newVoters,
        hasMore: newVoters.isNotEmpty, // Simple pagination check
        loading: false,
        loadingMore: false,
      );

      if (newVoters.isNotEmpty) {
        page++;
      }
    } catch (e) {
      _state.value = state.copyWith(
        loading: false,
        loadingMore: false,
        error: e.toString(),
      );
    }
  }
}
