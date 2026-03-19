import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class EdgeFunctionTestScreen extends StatefulWidget {
  const EdgeFunctionTestScreen({super.key});

  @override
  State<EdgeFunctionTestScreen> createState() => _EdgeFunctionTestScreenState();
}

class _EdgeFunctionTestScreenState extends State<EdgeFunctionTestScreen> {
  // We will store the fetched URL here. Null means we are still loading.
  String? imageUrl;
  // If the function fails, we store the error message here.
  String? errorMessage;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchImageFromEdgeFunction();
  }

  Future<void> _fetchImageFromEdgeFunction() async {
    try {
      // 1. Invoke the Edge Function (Make sure the name exactly matches your deployed function name)
      final response = await Supabase.instance.client.functions.invoke(
        'get_string',
      );

      // 2. Parse the response
      // Based on your Deno code, the response structure looks like this:
      // { "data": { "id": 1, "image_url": "https://..." } }

      final responseData = response.data;

      // Safety check: ensure 'data' exists in the response
      if (responseData != null && responseData['data'] != null) {
        // 🔹 IMPORTANT: Change 'image_url' to whatever the actual column name is in your 'images_for_ben' table!
        final fetchedUrl = responseData['data']['image_url'];

        setState(() {
          imageUrl = fetchedUrl;
          isLoading = false;
        });
      } else {
        setState(() {
          errorMessage =
              "Function succeeded, but 'data' was missing in the response.";
          isLoading = false;
        });
      }
    } on FunctionException catch (e) {
      // 1. Check if the error details contain our custom JSON {"message": "..."}
      String extractedMessage = "Unknown Edge Function Error";

      if (e.details is Map && (e.details as Map).containsKey('message')) {
        extractedMessage = (e.details as Map)['message'];
      } else if (e.details != null) {
        extractedMessage = e.details.toString();
      }

      setState(() {
        // e.status gives you the 500 code
        // e.reasonPhrase gives you the HTTP text (e.g., "Internal Server Error")
        errorMessage =
            'Error ${e.status}: $extractedMessage\n(${e.reasonPhrase ?? ""})';
        isLoading = false;
      });
    } catch (e) {
      // Catch generic Flutter/Network errors
      setState(() {
        errorMessage = 'Unexpected Error: $e';
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edge Function Test'),
        backgroundColor: const Color(0xFFFBFBF2), // Your app's theme color
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: _buildContent(),
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (isLoading) {
      return const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text("Calling Supabase Edge Function..."),
        ],
      );
    }

    if (errorMessage != null) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 48),
          const SizedBox(height: 16),
          Text(
            errorMessage!,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.red),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              setState(() {
                isLoading = true;
                errorMessage = null;
              });
              _fetchImageFromEdgeFunction();
            },
            child: const Text("Retry"),
          ),
        ],
      );
    }

    if (imageUrl != null) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            "Image retrieved successfully!",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          const SizedBox(height: 24),
          // 3. Display the Image
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              imageUrl!,
              height: 300,
              width: double.infinity,
              fit: BoxFit.cover,
              // Add a builder to handle broken links gracefully
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  height: 300,
                  color: Colors.grey[200],
                  child: const Center(
                    child: Text("URL loaded, but image failed to render."),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          Text(
            "URL: $imageUrl",
            style: const TextStyle(fontSize: 10, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ],
      );
    }

    return const Text("Something unexpected happened.");
  }
}
