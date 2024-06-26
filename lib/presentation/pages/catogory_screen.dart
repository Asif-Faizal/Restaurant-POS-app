import 'package:ballast_machn_test/presentation/pages/fooddetails_screen.dart';
import 'package:ballast_machn_test/presentation/pages/menu_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../data/models/food_model.dart';
import '../../data/providers/category_api_provider.dart';
import '../../data/repositories/category_repository.dart';
import '../../domain/usecases/fetch_categories.dart';
import '../blocs/category/category_bloc.dart';
import '../blocs/category/category_event.dart';
import '../blocs/category/category_state.dart';
import '../widgets/category_tile.dart';

class CategoryPage extends StatefulWidget {
  final int table;
  final String name;

  const CategoryPage({super.key, required this.table, required this.name});

  @override
  _CategoryPageState createState() => _CategoryPageState();
}

class _CategoryPageState extends State<CategoryPage> {
  String? _selectedCategory;
  TextEditingController _foodsearch = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage('lib/assets/bb.jpg'),
              fit: BoxFit.cover,
            ),
          ),
        ),
        Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            actions: [
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => MenuPage(
                              customerNumber: widget.name,
                              table: widget.table.toInt(),
                            )),
                  );
                },
                child: Icon(Icons.note),
              ),
              SizedBox(
                width: 10,
              )
            ],
            leading: IconButton(
              onPressed: () {
                Navigator.pop(context);
              },
              icon: const Icon(Icons.arrow_back_ios_new_rounded),
            ),
            elevation: 0,
            backgroundColor: Colors.transparent,
            foregroundColor: Colors.white,
            title: Text(
              'Table ${widget.table} - ${widget.name}',
              style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white),
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(150),
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  children: [
                    Material(
                      elevation: 5,
                      borderRadius: BorderRadius.circular(10),
                      child: TextField(
                        controller: _foodsearch,
                        decoration: InputDecoration(
                          hintText: 'Search Foods...',
                          prefixIcon: const Icon(Icons.search),
                          suffixIcon: Container(
                            padding: const EdgeInsets.all(5),
                            child: ElevatedButton(
                              onPressed: () async {
                                final food = await getFoodBasedOnSearch(
                                    _foodsearch.text);
                                Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) => FoodDetailsPage(
                                            food: food,
                                            customerName: widget.name,
                                            table: widget.table)));
                              },
                              style: ElevatedButton.styleFrom(
                                elevation: 5,
                                padding: const EdgeInsets.all(5),
                                shape: const CircleBorder(),
                              ),
                              child: const Icon(Icons.forward, size: 20),
                            ),
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                              vertical: 15, horizontal: 10),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          Expanded(
                            child: RadioListTile<String>(
                              title: const Text('Services',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold)),
                              value: 'Services',
                              groupValue: _selectedCategory,
                              onChanged: (value) {
                                setState(() {
                                  _selectedCategory = value;
                                });
                              },
                              activeColor: Colors.white,
                              dense: true,
                            ),
                          ),
                          Expanded(
                            child: RadioListTile<String>(
                              title: const Text('Goods',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold)),
                              value: 'Goods',
                              groupValue: _selectedCategory,
                              onChanged: (value) {
                                setState(() {
                                  _selectedCategory = value;
                                });
                              },
                              activeColor: Colors.white,
                              dense: true,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          body: BlocProvider(
            create: (context) => CategoryBloc(
              fetchCategories: FetchCategories(
                repository:
                    CategoryRepository(apiProvider: CategoryApiProvider()),
              ),
            )..add(FetchCategoriesEvent()),
            child: BlocBuilder<CategoryBloc, CategoryState>(
              builder: (context, state) {
                return _buildBody(state, context);
              },
            ),
          ),
        ),
      ],
    );
  }

  // Function to get Food object based on search text
  Future<Food> getFoodBasedOnSearch(String searchText) async {
    final response = await http.get(
        Uri.parse('http://10.0.2.2:3000/api/mainstockdupe/name/$searchText'));

    if (response.statusCode == 200) {
      final jsonData = json.decode(response.body) as List;
      if (jsonData.isNotEmpty) {
        return Food.fromJson(jsonData[0]);
      } else {
        throw Exception('Food not found');
      }
    } else {
      throw Exception('Failed to load food');
    }
  }

  Widget _buildBody(CategoryState state, BuildContext context) {
    if (state is CategoryLoading) {
      return const Center(child: CircularProgressIndicator());
    } else if (state is CategoryLoaded) {
      // Filter categories based on _selectedCategory
      final filteredCategories = _selectedCategory == null
          ? state.categories
          : state.categories
              .where((category) => category.SERorGOODS == _selectedCategory)
              .toList();

      return GridView.builder(
        itemCount: filteredCategories.length,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 10),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 5,
          crossAxisSpacing: 5,
        ),
        itemBuilder: (context, index) {
          final item = filteredCategories[index];
          return CategoryTile(
            item: item,
            table: widget.table,
            customerName: widget.name,
          );
        },
      );
    } else if (state is CategoryError) {
      return Center(child: Text(state.message));
    } else {
      return const Center(child: Text('No categories found'));
    }
  }
}
