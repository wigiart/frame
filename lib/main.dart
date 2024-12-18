import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:logging/logging.dart';

final _logger = Logger('ImageGeneratorPage');

void main() {
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((record) {
    debugPrint('${record.level.name}: ${record.message}');
  });

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Image Generator',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const ImageGeneratorPage(),
    );
  }
}

class ImageGeneratorPage extends StatefulWidget {
  const ImageGeneratorPage({super.key});

  @override
  State<ImageGeneratorPage> createState() => _ImageGeneratorPageState();
}

class _ImageGeneratorPageState extends State<ImageGeneratorPage> {
  final TextEditingController _nameController = TextEditingController();
  String _selectedCharacter = 'girl';
  String? _generatedImageUrl;
  bool _isLoading = false;

  final List<String> characters = [
    'girl',
    'boy',
    'cat',
    'dog',
    'rabbit',
    'panda',
    'unicorn',
  ];

  Future<void> generateImage() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _generatedImageUrl = null;
    });

    final prompt =
        'a $_selectedCharacter holding a birthday cake named "${_nameController.text}", beautiful scenery in the background, 3d Pixar style';

    try {
      final requestBody = {
        "taskType": "imageInference",
        "model": "runware:100@1",
        "positivePrompt": prompt,
        "height": 1024,
        "width": 576,
        "numberResults": 1,
        "outputType": ["URL"],
        "outputFormat": "PNG",
        "CFGScale": 7,
        "steps": 4,
        "scheduler": "Default",
        "includeCost": true,
      };

      _logger.info('Request body: ${jsonEncode(requestBody)}');

      final response = await http.post(
        Uri.parse('https://api.runware.ai/v1/imageInference'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer bO2dUv9OhD70N6KKbCGEjDGTdjRQn90n',
        },
        body: jsonEncode(requestBody),
      );

      _logger.info('Response status: ${response.statusCode}');
      _logger.info('Response body: ${response.body}');

      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        setState(() {
          _generatedImageUrl = data[0]['outputs']['URL'][0];
        });
      } else {
        final errorMessage = data['message'] ??
            data['error'] ??
            'Failed to generate image (Status: ${response.statusCode})';
        throw Exception(errorMessage);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Birthday Image Generator'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Enter Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedCharacter,
              decoration: const InputDecoration(
                labelText: 'Select Character',
                border: OutlineInputBorder(),
              ),
              items: characters.map((character) {
                return DropdownMenuItem(
                  value: character,
                  child: Text(character.toUpperCase()),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedCharacter = value!;
                });
              },
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isLoading ? null : generateImage,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: _isLoading
                    ? const CircularProgressIndicator()
                    : const Text('Generate Image'),
              ),
            ),
            const SizedBox(height: 16),
            if (_generatedImageUrl != null)
              Container(
                height: 400,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    _generatedImageUrl!,
                    fit: BoxFit.contain,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return const Center(child: CircularProgressIndicator());
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return const Center(child: Text('Error loading image'));
                    },
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }
}
