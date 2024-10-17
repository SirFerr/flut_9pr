import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:get_it/get_it.dart';

void main() {
  setupLocator();
  runApp(const MyApp());
}

final GetIt locator = GetIt.instance;

void setupLocator() {
  locator.registerLazySingleton(() => DioClient());
  locator.registerLazySingleton(() => RecipeRepository(locator<DioClient>()));
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Рецепты',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const RecipeListScreen(),
    );
  }
}

class RecipeListScreen extends StatefulWidget {
  const RecipeListScreen({Key? key}) : super(key: key);

  @override
  _RecipeListScreenState createState() => _RecipeListScreenState();
}

class _RecipeListScreenState extends State<RecipeListScreen> {
  final RecipeRepository _recipeRepository = locator<RecipeRepository>();

  List<dynamic> _recipes = [];
  bool _isLoading = false;

  Future<void> fetchRecipes(String query) async {
    setState(() {
      _isLoading = true;
    });
    try {
      final response = await _recipeRepository.fetchRecipes(query);
      setState(() {
        _recipes = response;
      });
    } catch (e) {
      print('Ошибка при получении рецептов: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Рецепты'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: const InputDecoration(
                labelText: 'Поиск рецептов',
                border: OutlineInputBorder(),
              ),
              onSubmitted: (query) {
                fetchRecipes(query);
              },
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
              itemCount: _recipes.length,
              itemBuilder: (context, index) {
                final recipe = _recipes[index];
                return Card(
                  margin: const EdgeInsets.all(16.0),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(16.0),
                          child: CachedNetworkImage(
                            fit: BoxFit.contain,
                            imageUrl: 'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcSMtt3aOrfYZ1KnQq4GK0vf9gkNBC07f72UWQ&s',
                            placeholder: (context, url) => const CircularProgressIndicator(),
                            errorWidget: (context, url, error) => const Icon(Icons.error),
                          ),
                        ),
                        const SizedBox(height: 8),
                        ListTile(
                          title: Text(
                            recipe['title'] ?? 'Без названия',
                            textAlign: TextAlign.start  ,
                          ),
                          subtitle: Text(
                            recipe['ingredients']?.replaceAll('|', '\n') ?? 'Нет ингредиентов',
                            textAlign: TextAlign.start,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}


class DioClient {
  final Dio _dio = Dio();

  Future<List<dynamic>> get(String url, {Map<String, dynamic>? queryParameters, Map<String, String>? headers}) async {
    final response = await _dio.get(
      url,
      queryParameters: queryParameters,
      options: Options(headers: headers),
    );
    return response.data;
  }
}

class RecipeRepository {
  final DioClient _dioClient;
  final String _apiUrl = 'https://api.api-ninjas.com/v1/recipe';
  final String _apiKey = '';

  RecipeRepository(this._dioClient);

  Future<List<dynamic>> fetchRecipes(String query) async {
    return await _dioClient.get(
      _apiUrl,
      queryParameters: {'query': query},
      headers: {'X-Api-Key': _apiKey},
    );
  }
}