import "package:flutter/material.dart";
import "package:loure/provider/data_util.dart";

import "package:loure/main.dart";
import "package:loure/util/dirtywords_util.dart";

class FilterProvider extends ChangeNotifier {
  static FilterProvider? _instance;

  Map<String, int> blocks = {};
  List<String> dirtywordList = [];

  late TrieTree trieTree;

  static FilterProvider getInstance() {
    if (_instance == null) {
      _instance = FilterProvider();
      final blockList = sharedPreferences.getStringList(DataKey.BLOCK_LIST);
      if (blockList != null && blockList.isNotEmpty) {
        for (final block in blockList) {
          _instance!.blocks[block] = 1;
        }
      }

      final dirtywordList =
          sharedPreferences.getStringList(DataKey.DIRTYWORD_LIST);
      if (dirtywordList != null && dirtywordList.isNotEmpty) {
        _instance!.dirtywordList = dirtywordList;
      }

      final wordsLength = _instance!.dirtywordList.length;
      List<List<int>> words = List.generate(wordsLength, (final index) {
        final word = _instance!.dirtywordList[index];
        return word.codeUnits;
      });
      _instance!.trieTree = buildTrieTree(words, null);
    }

    return _instance!;
  }

  bool checkDirtyword(final String targetStr) {
    if (dirtywordList.isEmpty) {
      return false;
    }
    return trieTree.check(targetStr);
  }

  void removeDirtyword(final String word) {
    dirtywordList.remove(word);
    final wordsLength = dirtywordList.length;
    List<List<int>> words = List.generate(wordsLength, (final index) {
      final word = _instance!.dirtywordList[index];
      return word.codeUnits;
    });
    trieTree = buildTrieTree(words, null);

    _updateDirtyword();
  }

  void addDirtyword(final String word) {
    dirtywordList.add(word);
    trieTree.root.insertWord(word.codeUnits, []);

    _updateDirtyword();
  }

  void _updateDirtyword() {
    sharedPreferences.setStringList(DataKey.DIRTYWORD_LIST, dirtywordList);
    notifyListeners();
  }

  bool checkBlock(final String pubkey) {
    return blocks[pubkey] != null;
  }

  void addBlock(final String pubkey) {
    blocks[pubkey] = 1;
    _updateBlock();
  }

  void removeBlock(final String pubkey) {
    blocks.remove(pubkey);
    _updateBlock();
  }

  void _updateBlock() {
    final list = blocks.keys.toList();
    sharedPreferences.setStringList(DataKey.BLOCK_LIST, list);
    notifyListeners();
  }
}
