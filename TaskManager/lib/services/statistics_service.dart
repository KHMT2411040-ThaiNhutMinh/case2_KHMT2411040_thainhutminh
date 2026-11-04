import '../models/statistics.dart';
import 'api_client.dart';

class StatisticsService {
  Future<StatusCounts> tasks() async {
    final data =
        await ApiClient.request('GET', '/statistics/tasks', auth: true);
    return StatusCounts.fromJson(data);
  }

  Future<AssignmentStats> assignments() async {
    final data =
        await ApiClient.request('GET', '/statistics/assignments', auth: true);
    return AssignmentStats.fromJson(data);
  }

  Future<DeadlineStats> deadlines({int days = 7}) async {
    final data = await ApiClient.request(
        'GET', '/statistics/deadlines?days=$days',
        auth: true);
    return DeadlineStats.fromJson(data);
  }
}