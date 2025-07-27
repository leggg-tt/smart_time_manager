import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'providers/task_provider.dart';
import 'providers/time_block_provider.dart';
import 'providers/theme_provider.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('en_US', null);  //初始化英文的日期格式,await确保初始化完成后与再继续
  runApp(const MyApp());
}
//My App类定义
class MyApp extends StatelessWidget {  //StatelessWidget无状态组件,组件本身不发生改变适合当作应用根组件
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {  //重写build方法
    return MultiProvider(  //允许注册多个provider
      providers: [
        //三个全局状态管理器.TaskProvider:管理任务数据;TimeBlockProvider:管理时间块数据;添加主题提供者
        ChangeNotifierProvider(create: (_) => TaskProvider()),
        ChangeNotifierProvider(create: (_) => TimeBlockProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      // 使用Consumer包裹MaterialApp以监听主题变化
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: 'Smart Time Manager',  //应用标题
            // 保持原有的浅色主题配置
            theme: ThemeData(  //应用主题背景
              colorScheme: ColorScheme.fromSeed(
                seedColor: Colors.blue,
                brightness: Brightness.light,
              ),
              useMaterial3: true,
              appBarTheme: const AppBarTheme(   //自定义应用栏主题
                centerTitle: true,  //居中显示
                elevation: 0,  //移除阴影效果
              ),
            ),
            // 添加深色主题配置
            darkTheme: ThemeData(
              colorScheme: ColorScheme.fromSeed(
                seedColor: Colors.blue,
                brightness: Brightness.dark,
              ),
              useMaterial3: true,
              appBarTheme: const AppBarTheme(
                centerTitle: true,
                elevation: 0,
              ),
            ),
            // 使用主题提供者的主题模式
            themeMode: themeProvider.actualThemeMode,
            home: const HomeScreen(),  //设置应用主页面为HomeScreen
            debugShowCheckedModeBanner: false, //隐藏debug标签
          );
        },
      ),
    );
  }
}