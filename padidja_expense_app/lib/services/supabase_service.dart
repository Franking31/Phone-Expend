import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  static Future<void> initialize() async {
    await Supabase.initialize(
      url: 'https://iufxtuntlqryoesnrmyr.supabase.co', // Remplacez par votre URL Supabase
      anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Iml1Znh0dW50bHFyeW9lc25ybXlyIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTIwNTY1MjcsImV4cCI6MjA2NzYzMjUyN30.sELP7l2Xx3FwoV7Aq7oyzRnNqpeqfppCzFcYeW6gN9w', // Remplacez par votre clé anonyme
    );
  }

  static SupabaseClient get client => Supabase.instance.client;
}