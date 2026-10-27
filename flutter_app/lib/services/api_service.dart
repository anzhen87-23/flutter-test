import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../models/note.dart';
import '../models/folder.dart';

/// API 服务类
class ApiService {
  static const String baseUrl = 'https://www.anzhenliuli.top/api';
  static const String serverUrl = 'https://www.anzhenliuli.top';
  static const String tokenKey = 'auth_token';
  static const String userKey = 'user_info';

  /// 获取 Token
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(tokenKey);
  }

  /// 保存 Token
  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(tokenKey, token);
  }

  /// 清除 Token
  static Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(tokenKey);
    await prefs.remove(userKey);
  }

  /// 获取当前用户
  static Future<User?> getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString(userKey);
    if (userJson == null) return null;
    try {
      return User.fromJson(jsonDecode(userJson));
    } catch (e) {
      return null;
    }
  }

  /// 保存用户信息
  static Future<void> saveUser(User user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(userKey, jsonEncode(user.toJson()));
  }

  /// 是否已登录
  static Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  /// 通用请求方法
  static Future<Map<String, dynamic>> request(
    String method,
    String path, {
    Map<String, dynamic>? data,
  }) async {
    final url = Uri.parse('$baseUrl$path');
    final token = await getToken();

    debugPrint('════════════════════════════════════════════');
    debugPrint('🌐 API Request: $method $url');
    if (data != null) {
      debugPrint('📤 Request Data: $data');
    }
    if (token != null && token.isNotEmpty) {
      debugPrint('🔑 Token: ${token.substring(0, 20)}...');
    }

    final headers = <String, String>{
      'Content-Type': 'application/json',
    };

    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }

    http.Response response;

    try {
      switch (method.toUpperCase()) {
        case 'GET':
          response = await http.get(url, headers: headers);
          break;
        case 'POST':
          response = await http.post(
            url,
            headers: headers,
            body: data != null ? jsonEncode(data) : null,
          );
          break;
        case 'PUT':
          response = await http.put(
            url,
            headers: headers,
            body: data != null ? jsonEncode(data) : null,
          );
          break;
        case 'DELETE':
          response = await http.delete(url, headers: headers);
          break;
        default:
          throw Exception('不支持的请求方法: $method');
      }

      debugPrint('📥 Response Status: ${response.statusCode}');
      debugPrint('📥 Response Body: ${response.body}');

      final result = jsonDecode(response.body);

      if (response.statusCode == 401) {
        await clearToken();
        throw Exception('登录已过期，请重新登录');
      }

      if (response.statusCode >= 400) {
        debugPrint('❌ API Error: ${result['message'] ?? '请求失败'}');
        throw Exception(result['message'] ?? '请求失败');
      }

      debugPrint('✅ API Success');
      debugPrint('════════════════════════════════════════════');
      return result;
    } catch (e) {
      debugPrint('❌ Request Failed: $e');
      debugPrint('════════════════════════════════════════════');
      if (e is Exception && e.toString().contains('SocketException')) {
        throw Exception('网络连接失败，请检查后端服务是否启动');
      }
      rethrow;
    }
  }
}

/// 认证 API
class AuthApi {
  /// 发送验证码
  static Future<void> sendCode(String target, String type) async {
    await ApiService.request('POST', '/auth/send-code', data: {
      'target': target,
      'type': type,
    });
  }

  /// 手机号注册
  static Future<User> registerByPhone({
    required String phone,
    required String code,
    required String password,
    String nickname = '',
  }) async {
    final result = await ApiService.request('POST', '/auth/register/phone', data: {
      'phone': phone,
      'code': code,
      'password': password,
      'nickname': nickname,
    });

    final token = result['data']['token'] as String;
    final user = User.fromJson(result['data']['user']);

    await ApiService.saveToken(token);
    await ApiService.saveUser(user);

    return user;
  }

  /// 邮箱注册
  static Future<User> registerByEmail({
    required String email,
    required String code,
    required String password,
    String nickname = '',
  }) async {
    final result = await ApiService.request('POST', '/auth/register/email', data: {
      'email': email,
      'code': code,
      'password': password,
      'nickname': nickname,
    });

    final token = result['data']['token'] as String;
    final user = User.fromJson(result['data']['user']);

    await ApiService.saveToken(token);
    await ApiService.saveUser(user);

    return user;
  }

  /// 登录
  static Future<User> login(String account, String password) async {
    final result = await ApiService.request('POST', '/auth/login', data: {
      'account': account,
      'password': password,
    });

    final token = result['data']['token'] as String;
    final user = User.fromJson(result['data']['user']);

    await ApiService.saveToken(token);
    await ApiService.saveUser(user);

    return user;
  }

  /// 重置密码
  static Future<void> resetPassword({
    required String account,
    required String code,
    required String newPassword,
  }) async {
    await ApiService.request('POST', '/auth/reset-password', data: {
      'account': account,
      'code': code,
      'new_password': newPassword,
    });
  }
}

/// 笔记 API
class NotesApi {
  /// 获取笔记列表
  static Future<NotesResponse> list({
    int page = 1,
    int pageSize = 20,
    int? folderId,
  }) async {
    var path = '/notes?page=$page&page_size=$pageSize';
    if (folderId != null) {
      path += '&folder_id=$folderId';
    }

    final result = await ApiService.request('GET', path);
    return NotesResponse.fromJson(result['data']);
  }

  /// 获取笔记详情
  static Future<Note> get(int id) async {
    final result = await ApiService.request('GET', '/notes/$id');
    return Note.fromJson(result['data']);
  }

  /// 创建笔记
  static Future<Note> create({
    required String title,
    required String content,
    int? folderId,
  }) async {
    final data = <String, dynamic>{
      'title': title,
      'content': content,
    };
    if (folderId != null) {
      data['folder_id'] = folderId;
    }

    debugPrint('📤 [NotesApi.create] data: $data');
    debugPrint('📤 [NotesApi.create] folderId type: ${folderId.runtimeType}');

    final result = await ApiService.request('POST', '/notes', data: data);
    return Note.fromJson(result['data']);
  }

  /// 更新笔记
  static Future<Note> update(int id, {
    required String title,
    required String content,
    int? folderId,
  }) async {
    final data = <String, dynamic>{
      'title': title,
      'content': content,
    };
    if (folderId != null) {
      data['folder_id'] = folderId;
    }

    debugPrint('📤 [NotesApi.update] id: $id, data: $data');
    debugPrint('📤 [NotesApi.update] folderId type: ${folderId.runtimeType}');

    final result = await ApiService.request('PUT', '/notes/$id', data: data);
    return Note.fromJson(result['data']);
  }

  /// 删除笔记
  static Future<void> delete(int id) async {
    await ApiService.request('DELETE', '/notes/$id');
  }

  /// 上传笔记图片
  static Future<Map<String, dynamic>> uploadImage(String filePath) async {
    final url = Uri.parse('${ApiService.baseUrl}/notes/upload-image');
    final token = await ApiService.getToken();

    // 根据文件扩展名推断 Content-Type
    final ext = filePath.split('.').last.toLowerCase();
    String mimeType;
    switch (ext) {
      case 'jpg':
      case 'jpeg':
        mimeType = 'image/jpeg';
        break;
      case 'png':
        mimeType = 'image/png';
        break;
      case 'gif':
        mimeType = 'image/gif';
        break;
      case 'webp':
        mimeType = 'image/webp';
        break;
      default:
        mimeType = 'application/octet-stream';
    }

    debugPrint('════════════════════════════════════════════');
    debugPrint('📤 [NoteImage Upload] 开始上传');
    debugPrint('📤 [NoteImage Upload] URL: $url');
    debugPrint('📤 [NoteImage Upload] 文件路径: $filePath');
    debugPrint('📤 [NoteImage Upload] MIME 类型: $mimeType');

    final request = http.MultipartRequest('POST', url);

    if (token != null && token.isNotEmpty) {
      request.headers['Authorization'] = 'Bearer $token';
    }

    request.files.add(await http.MultipartFile.fromPath(
      'image',
      filePath,
      contentType: MediaType.parse(mimeType),
    ));

    try {
      final streamedResponse = await request.send();
      final responseBody = await streamedResponse.stream.bytesToString();

      debugPrint('📥 [NoteImage Upload] 响应状态码: ${streamedResponse.statusCode}');
      debugPrint('📥 [NoteImage Upload] 响应体: $responseBody');

      final result = jsonDecode(responseBody);

      if (streamedResponse.statusCode == 401) {
        await ApiService.clearToken();
        throw Exception('登录已过期，请重新登录');
      }

      if (streamedResponse.statusCode >= 400) {
        final message = result['message'] ?? '上传失败 (HTTP ${streamedResponse.statusCode})';
        debugPrint('❌ [NoteImage Upload] 上传失败: $message');
        throw Exception(message);
      }

      final data = result['data'] as Map<String, dynamic>;
      debugPrint('✅ [NoteImage Upload] 上传成功: ${data['url']}');
      debugPrint('════════════════════════════════════════════');
      return data;
    } catch (e) {
      debugPrint('❌ [NoteImage Upload] 请求异常: $e');
      debugPrint('════════════════════════════════════════════');
      if (e is Exception && e.toString().contains('SocketException')) {
        throw Exception('网络连接失败，请检查后端服务是否启动');
      }
      rethrow;
    }
  }

  /// 上传笔记视频
  static Future<Map<String, dynamic>> uploadVideo(String filePath) async {
    final url = Uri.parse('${ApiService.baseUrl}/notes/upload-image');
    final token = await ApiService.getToken();

    final ext = filePath.split('.').last.toLowerCase();
    String mimeType;
    switch (ext) {
      case 'mp4':
        mimeType = 'video/mp4';
        break;
      case 'mov':
        mimeType = 'video/quicktime';
        break;
      case 'webm':
        mimeType = 'video/webm';
        break;
      case 'avi':
        mimeType = 'video/x-msvideo';
        break;
      default:
        mimeType = 'application/octet-stream';
    }

    debugPrint('📤 [NoteVideo Upload] 开始上传: $filePath, MIME: $mimeType');

    final request = http.MultipartRequest('POST', url);

    if (token != null && token.isNotEmpty) {
      request.headers['Authorization'] = 'Bearer $token';
    }

    request.files.add(await http.MultipartFile.fromPath(
      'video',
      filePath,
      contentType: MediaType.parse(mimeType),
    ));

    try {
      final streamedResponse = await request.send();
      final responseBody = await streamedResponse.stream.bytesToString();

      final result = jsonDecode(responseBody);

      if (streamedResponse.statusCode == 401) {
        await ApiService.clearToken();
        throw Exception('登录已过期，请重新登录');
      }

      if (streamedResponse.statusCode >= 400) {
        final message = result['message'] ?? '上传视频失败 (HTTP ${streamedResponse.statusCode})';
        throw Exception(message);
      }

      final data = result['data'] as Map<String, dynamic>;
      debugPrint('✅ [NoteVideo Upload] 上传成功: ${data['url']}');
      return data;
    } catch (e) {
      if (e is Exception && e.toString().contains('SocketException')) {
        throw Exception('网络连接失败，请检查后端服务是否启动');
      }
      rethrow;
    }
  }

  /// 删除笔记图片
  static Future<void> deleteImage(String filename) async {
    await ApiService.request('DELETE', '/note-images/$filename');
  }
}

/// 文件夹 API
class FoldersApi {
  /// 获取文件夹列表
  static Future<List<Folder>> list() async {
    final result = await ApiService.request('GET', '/folders');
    final list = result['data'] as List;
    return list.map((item) => Folder.fromJson(item)).toList();
  }

  /// 创建文件夹
  static Future<Folder> create(String name) async {
    final result = await ApiService.request('POST', '/folders', data: {
      'name': name,
    });
    return Folder.fromJson(result['data']);
  }

  /// 更新文件夹
  static Future<Folder> update(int id, String name) async {
    final result = await ApiService.request('PUT', '/folders/$id', data: {
      'name': name,
    });
    return Folder.fromJson(result['data']);
  }

  /// 删除文件夹
  static Future<void> delete(int id) async {
    await ApiService.request('DELETE', '/folders/$id');
  }
}

/// 个人信息 API
class ProfileApi {
  /// 获取个人信息
  static Future<User> get() async {
    final result = await ApiService.request('GET', '/profile');
    final user = User.fromJson(result['data']);
    await ApiService.saveUser(user);
    return user;
  }

  /// 更新昵称
  static Future<void> updateNickname(String nickname) async {
    await ApiService.request('PUT', '/profile/nickname', data: {
      'nickname': nickname,
    });
  }

  /// 更新生日
  static Future<void> updateBirthday(DateTime birthday) async {
    await ApiService.request('PUT', '/profile/birthday', data: {
      'birthday': birthday.toIso8601String(),
    });
  }

  /// 更新手机号
  static Future<void> updatePhone({
    required String newPhone,
    required String code,
    required String password,
  }) async {
    await ApiService.request('PUT', '/profile/phone', data: {
      'new_phone': newPhone,
      'code': code,
      'password': password,
    });
  }

  /// 更新邮箱
  static Future<void> updateEmail({
    required String newEmail,
    required String code,
    required String password,
  }) async {
    await ApiService.request('PUT', '/profile/email', data: {
      'new_email': newEmail,
      'code': code,
      'password': password,
    });
  }

  /// 修改密码
  static Future<void> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    await ApiService.request('PUT', '/profile/password', data: {
      'old_password': oldPassword,
      'new_password': newPassword,
    });
  }

  /// 上传头像
  static Future<String> uploadAvatar(String filePath) async {
    final url = Uri.parse('${ApiService.baseUrl}/profile/avatar');
    final token = await ApiService.getToken();

    // 根据文件扩展名推断 Content-Type
    final ext = filePath.split('.').last.toLowerCase();
    String mimeType;
    switch (ext) {
      case 'jpg':
      case 'jpeg':
        mimeType = 'image/jpeg';
        break;
      case 'png':
        mimeType = 'image/png';
        break;
      case 'gif':
        mimeType = 'image/gif';
        break;
      default:
        mimeType = 'application/octet-stream';
    }

    debugPrint('════════════════════════════════════════════');
    debugPrint('📤 [Avatar Upload] 开始上传');
    debugPrint('📤 [Avatar Upload] URL: $url');
    debugPrint('📤 [Avatar Upload] 文件路径: $filePath');
    debugPrint('📤 [Avatar Upload] 文件扩展名: $ext');
    debugPrint('📤 [Avatar Upload] MIME 类型: $mimeType');
    debugPrint('📤 [Avatar Upload] Token: ${token != null && token.isNotEmpty ? "${token.substring(0, 20)}..." : "无"}');

    final request = http.MultipartRequest('POST', url);

    if (token != null && token.isNotEmpty) {
      request.headers['Authorization'] = 'Bearer $token';
    }

    // 显式设置 Content-Type，避免默认为 application/octet-stream
    request.files.add(await http.MultipartFile.fromPath(
      'avatar',
      filePath,
      contentType: MediaType.parse(mimeType),
    ));

    debugPrint('📤 [Avatar Upload] 请求已发送，等待响应...');

    try {
      final streamedResponse = await request.send();
      final responseBody = await streamedResponse.stream.bytesToString();

      debugPrint('📥 [Avatar Upload] 响应状态码: ${streamedResponse.statusCode}');
      debugPrint('📥 [Avatar Upload] 响应头: ${streamedResponse.headers}');
      debugPrint('📥 [Avatar Upload] 响应体: $responseBody');

      final result = jsonDecode(responseBody);

      if (streamedResponse.statusCode == 401) {
        await ApiService.clearToken();
        throw Exception('登录已过期，请重新登录');
      }

      if (streamedResponse.statusCode >= 400) {
        final message = result['message'] ?? '上传失败 (HTTP ${streamedResponse.statusCode})';
        debugPrint('❌ [Avatar Upload] 上传失败: $message');
        throw Exception(message);
      }

      final avatarUrl = result['data']['avatar_url'] as String;
      debugPrint('✅ [Avatar Upload] 上传成功: $avatarUrl');
      debugPrint('════════════════════════════════════════════');
      return avatarUrl;
    } catch (e) {
      debugPrint('❌ [Avatar Upload] 请求异常: $e');
      debugPrint('════════════════════════════════════════════');
      if (e is Exception && e.toString().contains('SocketException')) {
        throw Exception('网络连接失败，请检查后端服务是否启动');
      }
      rethrow;
    }
  }
}
