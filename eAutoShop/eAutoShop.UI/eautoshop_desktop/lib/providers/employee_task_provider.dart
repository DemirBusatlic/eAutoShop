import 'dart:convert';

import 'package:eautoshop_desktop/models/employee_task/employee_task.dart';
import 'package:eautoshop_desktop/models/employee_task/employee_task_insert.dart';
import 'package:eautoshop_desktop/models/employee_task/employee_task_search_object.dart';
import 'package:eautoshop_desktop/models/search_result.dart';
import 'package:eautoshop_desktop/providers/base_provider.dart';
import 'package:eautoshop_desktop/utilities/custom_exception.dart';
import 'package:http/http.dart' as http;

class EmployeeTaskProvider
    extends BaseProvider<EmployeeTask, EmployeeTaskInsert> {
  EmployeeTaskProvider() : super('EmployeeTask');

  List<EmployeeTask> tasks = [];
  int countOfItems = 0;
  bool isLoading = false;

  Future<void> getTasks({
    required bool isManager,
    required int page,
    required int pageSize,
    EmployeeTaskSearchObject? search,
  }) async {
    isLoading = true;
    notifyListeners();

    try {
      final queryParameters = <String, dynamic>{
        if (search != null) ...search.toJson(),
        'Page': page,
        'PageSize': pageSize,
      };

      final SearchResult<EmployeeTask> searchResult = await get(
        customEndpoint: isManager ? '' : 'GetByEmployee',
        filter: queryParameters,
        fromJson: EmployeeTask.fromJson,
      );

      tasks = searchResult.result;
      countOfItems = searchResult.count;
    } catch (_) {
      tasks = [];
      countOfItems = 0;
      rethrow;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> createTask(EmployeeTaskInsert request) async {
    await insert(request, toJson: (item) => item.toJson());
  }

  Future<EmployeeTask> completeTask(int id) async {
    try {
      final response = await http.put(
        Uri.parse('${BaseProvider.baseUrl}/$endpoint/Complete/$id'),
        headers: await createHeaders(),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final task = EmployeeTask.fromJson(
          jsonDecode(response.body) as Map<String, dynamic>,
        );

        notifyListeners();
        return task;
      }

      handleHttpError(response);
    } on CustomException {
      rethrow;
    } catch (_) {
      throw const CustomException(
        'Nije moguće pristupiti serveru. '
        'Provjerite da li je API pokrenut.',
      );
    }
  }
}
