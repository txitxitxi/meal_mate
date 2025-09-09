import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

import '../models/user.dart';

class LoginManager extends ChangeNotifier {
  // 单例模式
  static final LoginManager _instance = LoginManager._internal();
  factory LoginManager() => _instance;
  LoginManager._internal();

  // SharedPreferences 键名
  static const String _userKey = 'current_user';

  // 当前用户信息，可选类型用于判断是否登录
  User? _currentUser;
  User? get currentUser => _currentUser;

  // 登录状态
  bool get isLoggedIn => _currentUser != null;

  // 登录加载状态
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  // 错误信息
  String? _error;
  String? get error => _error;

  // 设置加载状态
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  // 设置错误信息
  void _setError(String? error) {
    _error = error;
    notifyListeners();
  }

  // 设置用户信息并持久化
  Future<void> _setUser(User? user) async {
    _currentUser = user;
    await _saveUserToStorage(user);
    notifyListeners();
  }

  // 保存用户信息到本地存储
  Future<void> _saveUserToStorage(User? user) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (user != null) {
        final userJson = jsonEncode(user.toMap());
        await prefs.setString(_userKey, userJson);
        if (kDebugMode) {
          print('用户信息已保存到本地存储');
        }
      } else {
        await prefs.remove(_userKey);
        if (kDebugMode) {
          print('用户信息已从本地存储删除');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('保存用户信息失败: $e');
      }
    }
  }

  // 从本地存储加载用户信息
  Future<User?> _loadUserFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString(_userKey);
      if (userJson != null) {
        final userMap = jsonDecode(userJson) as Map<String, dynamic>;
        final user = User.fromMap(userMap);
        if (kDebugMode) {
          print('从本地存储加载用户信息: ${user.email}');
        }
        return user;
      }
    } catch (e) {
      if (kDebugMode) {
        print('加载用户信息失败: $e');
      }
    }
    return null;
  }

  // 谷歌登录
  Future<bool> signInWithGoogle() async {
    _setLoading(true);
    _setError(null);

    try {
      // 暂时处理成必然成功，存入假数据
      await Future.delayed(const Duration(seconds: 1)); // 模拟网络请求

      // 创建假的用户数据
      final fakeUser = User(
        id: 'google_${DateTime.now().millisecondsSinceEpoch}',
        email: 'user@gmail.com',
        name: 'Google 用户',
        avatar: 'https://via.placeholder.com/150',
        provider: LoginProvider.google,
        createdAt: DateTime.now(),
        lastLoginAt: DateTime.now(),
      );

      await _setUser(fakeUser);
      _setLoading(false);

      if (kDebugMode) {
        print('Google 登录成功: ${fakeUser.toString()}');
      }

      return true;
    } catch (e) {
      _setError('Google 登录失败: $e');
      _setLoading(false);
      return false;
    }
  }

  // 苹果登录（仅在支持的平台上）
  Future<bool> signInWithApple() async {
    if (!Platform.isIOS && !Platform.isMacOS) {
      _setError('苹果登录仅在 iOS 和 macOS 上支持');
      return false;
    }

    _setLoading(true);
    _setError(null);

    try {
      // 暂时处理成必然成功，存入假数据
      await Future.delayed(const Duration(seconds: 1)); // 模拟网络请求

      // 创建假的用户数据
      final fakeUser = User(
        id: 'apple_${DateTime.now().millisecondsSinceEpoch}',
        email: 'user@privaterelay.appleid.com',
        name: 'Apple 用户',
        avatar: 'https://via.placeholder.com/150',
        provider: LoginProvider.apple,
        createdAt: DateTime.now(),
        lastLoginAt: DateTime.now(),
      );

      await _setUser(fakeUser);
      _setLoading(false);

      if (kDebugMode) {
        print('Apple 登录成功: ${fakeUser.toString()}');
      }

      return true;
    } catch (e) {
      _setError('Apple 登录失败: $e');
      _setLoading(false);
      return false;
    }
  }

  // 登出
  Future<void> signOut() async {
    _setLoading(true);

    try {
      // 登出所有第三方服务
      final GoogleSignIn googleSignIn = GoogleSignIn();
      if (await googleSignIn.isSignedIn()) {
        await googleSignIn.signOut();
      }

      // 登出 Supabase
      await supabase.Supabase.instance.client.auth.signOut();

      await _setUser(null);
      _setError(null);

      if (kDebugMode) {
        print('用户已登出');
      }
    } catch (e) {
      _setError('登出失败: $e');
    } finally {
      _setLoading(false);
    }
  }

  // 清除错误信息
  void clearError() {
    _setError(null);
  }

  // 刷新用户信息
  Future<void> refreshUser() async {
    if (!isLoggedIn) return;

    try {
      final currentSession =
          supabase.Supabase.instance.client.auth.currentSession;
      if (currentSession?.user != null) {
        final user = User(
          id: currentSession!.user.id,
          email: currentSession.user.email ?? '',
          name: currentSession.user.userMetadata?['full_name'] as String?,
          avatar: currentSession.user.userMetadata?['avatar_url'] as String?,
          provider: LoginProvider.values
              .byName(currentSession.user.appMetadata['provider'] ?? 'email'),
          createdAt: DateTime.parse(currentSession.user.createdAt),
          lastLoginAt: DateTime.now(),
        );

        await _setUser(user);
      }
    } catch (e) {
      if (kDebugMode) {
        print('刷新用户信息失败: $e');
      }
    }
  }

  // 初始化，从本地存储加载用户信息
  Future<void> initialize() async {
    try {
      // 首先尝试从本地存储加载用户信息
      final savedUser = await _loadUserFromStorage();
      if (savedUser != null) {
        _currentUser = savedUser; // 直接设置，不需要触发 notifyListeners
        if (kDebugMode) {
          print('LoginManager 初始化完成，加载用户: ${savedUser.email}');
        }
      } else {
        if (kDebugMode) {
          print('LoginManager 初始化完成，未找到已保存的用户');
        }
      }

      // 然后检查 Supabase 会话（可选，用于真实登录时）
      // final session = supabase.Supabase.instance.client.auth.currentSession;
      // if (session?.user != null) {
      //   await refreshUser();
      // }
    } catch (e) {
      if (kDebugMode) {
        print('LoginManager 初始化失败: $e');
      }
    }
  }
}
