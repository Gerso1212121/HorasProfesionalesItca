// lib/Frontend/Modules/Diary/ViewModels/diary_viewmodel.dart
import 'package:flutter/material.dart';
import 'package:horas2/Frontend/Modules/Diary/model/diario_entry.dart';

class DiaryViewModel extends ChangeNotifier {
  List<DiaryEntry> _entries = [];
  DiaryEntry? _currentEntry;

  List<DiaryEntry> get entries => _entries;
  DiaryEntry? get currentEntry => _currentEntry;

  void loadEntries(List<DiaryEntry> entries) {
    _entries = entries;
    notifyListeners();
  }

  void createNewEntry() {
    _currentEntry = DiaryEntry(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: '',
      content: '',
      date: DateTime.now(),
    );
    notifyListeners();
  }

  void editEntry(DiaryEntry entry) {
    _currentEntry = entry;
    notifyListeners();
  }

  void saveEntry(DiaryEntry entry) {
    final index = _entries.indexWhere((e) => e.id == entry.id);
    if (index >= 0) {
      _entries[index] = entry;
    } else {
      _entries.add(entry);
    }
    _currentEntry = null;
    notifyListeners();
  }

  void deleteEntry(String id) {
    _entries.removeWhere((entry) => entry.id == id);
    notifyListeners();
  }

  void updateCurrentEntry({
    String? title,
    String? content,
    DateTime? date,
    String? emoji,
    List<String>? images,
    List<ContentBlock>? contentBlocks,
  }) {
    if (_currentEntry == null) return;

    _currentEntry = DiaryEntry(
      id: _currentEntry!.id,
      title: title ?? _currentEntry!.title,
      content: content ?? _currentEntry!.content,
      date: date ?? _currentEntry!.date,
      emoji: emoji ?? _currentEntry!.emoji,
      images: images ?? _currentEntry!.images,
      contentBlocks: contentBlocks ?? _currentEntry!.contentBlocks,
    );
    notifyListeners();
  }
}