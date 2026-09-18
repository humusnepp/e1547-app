import 'package:dio/dio.dart';
import 'package:e1547/user/user.dart';

class UserClient {
  UserClient({required this.dio});

  final Dio dio;

  // Technically missing users()
  Future<User> get({required int id, CancelToken? cancelToken}) =>
      _get(id.toString(), cancelToken: cancelToken);

  Future<User> getByName({required String name, CancelToken? cancelToken}) =>
      _get(name, cancelToken: cancelToken);

  Future<User> _get(String lookup, {CancelToken? cancelToken}) => dio
      .get('/users/$lookup.json', cancelToken: cancelToken)
      .then((response) => E621User.fromJson(response.data));
}
