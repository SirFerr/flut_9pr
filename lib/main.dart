import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';

import 'api.dart';

void main() {
  setupLocator();
  runApp(const MyApp());
}

// Настройка GetIt
final getIt = GetIt.instance;

void setupLocator() {
  getIt.registerSingleton<Dio>(Dio());
  getIt.registerLazySingleton(() => RecipeService(getIt<Dio>()));
}

// RecipeService для работы с API
class RecipeService {
  final Dio dio;
  final String _apiUrl = 'https://api.api-ninjas.com/v1/recipe';
  final String _apiKey = API;

  RecipeService(this.dio);

  Future<List<dynamic>> fetchRecipes(String query) async {
    final response = await dio.get(
      _apiUrl,
      queryParameters: {'query': query},
      options: Options(headers: {'X-Api-Key': _apiKey}),
    );
    return response.data;
  }
}

// InheritedWidget для управления состоянием
class RecipeInheritedWidget extends InheritedWidget {
  final List<dynamic> recipes;
  final bool isLoading;

  const RecipeInheritedWidget({
    required this.recipes,
    required this.isLoading,
    required Widget child,
  }) : super(child: child);

  static RecipeInheritedWidget? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<RecipeInheritedWidget>();
  }

  @override
  bool updateShouldNotify(covariant RecipeInheritedWidget oldWidget) {
    return recipes != oldWidget.recipes || isLoading != oldWidget.isLoading;
  }
}

// Основное приложение
class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Рецепты',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const RecipeProvider(),
    );
  }
}

// Провайдер, связывающий GetIt и InheritedWidget
class RecipeProvider extends StatefulWidget {
  const RecipeProvider({Key? key}) : super(key: key);

  @override
  State<RecipeProvider> createState() => _RecipeProviderState();
}

class _RecipeProviderState extends State<RecipeProvider> {
  final RecipeService _recipeService = getIt<RecipeService>();

  List<dynamic> _recipes = [];
  bool _isLoading = false;

  Future<void> fetchRecipes(String query) async {
    setState(() => _isLoading = true);
    try {
      _recipes = await _recipeService.fetchRecipes(query);
    } catch (e) {
      print('Ошибка: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return RecipeInheritedWidget(
      recipes: _recipes,
      isLoading: _isLoading,
      child: RecipeListScreen(fetchRecipes: fetchRecipes),
    );
  }
}

// Экран с отображением рецептов
class RecipeListScreen extends StatelessWidget {
  final Function(String) fetchRecipes;

  const RecipeListScreen({Key? key, required this.fetchRecipes})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final recipes = RecipeInheritedWidget.of(context)!.recipes;
    final isLoading = RecipeInheritedWidget.of(context)!.isLoading;

    return Scaffold(
      appBar: AppBar(title: const Text('Рецепты')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: const InputDecoration(
                labelText: 'Поиск рецептов',
                border: OutlineInputBorder(),
              ),
              onSubmitted: fetchRecipes,
            ),
          ),
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : Expanded(
            child: ListView.builder(
              itemCount: recipes.length,
              itemBuilder: (context, index) {
                final recipe = recipes[index];
                return ListTile(
                  title: Text(recipe['title'] ?? 'Без названия'),
                  subtitle: Text(recipe['ingredients']?.replaceAll('|', '\n') ?? ''),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
