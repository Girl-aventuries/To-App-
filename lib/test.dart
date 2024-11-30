import 'package:flutter/material.dart';
import 'package:meu_app/DataBase.dart';  // Ajuste conforme o caminho do seu DB

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('Teste de Tags')),
        body: const TagList(),
      ),
    );
  }
}

class TagList extends StatefulWidget {
  const TagList({super.key});

  @override
  _TagListState createState() => _TagListState();
}

class _TagListState extends State<TagList> {
  late Future<List<Map<String, dynamic>>> _tags;

  @override
  void initState() {
    super.initState();
    _loadTags();
  }

  void _loadTags() {
    _tags = DB.instance.getTags();  // Ajuste para a função correta do seu DB
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _tags,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return const Center(child: Text('Erro ao carregar as tags.'));
        }

        final tags = snapshot.data ?? [];
        if (tags.isEmpty) {
          return const Center(child: Text('Nenhuma tag encontrada.'));
        }

        return ListView.builder(
          itemCount: tags.length,
          itemBuilder: (context, index) {
            final tag = tags[index];
            final tagColor = (tag['color'] != null)
                ? Color(tag['color']).withOpacity(0.5)
                : Colors.grey.withOpacity(0.5);

            return ListTile(
              title: Text(tag['name'] ?? 'Sem nome'),
              subtitle: Text(tag['color'] ?? 'Sem cor'),
              tileColor: tagColor,
            );
          },
        );
      },
    );
  }
}
