TrieTree buildTrieTree(final List<List<int>> words, List<int>? skips) {
  skips ??= [];

  final tree = TrieTree(TrieNode())..skips = skips;

  for (final word in words) {
    tree.root.insertWord(word, skips);
  }

  return tree;
}

class TrieTree {
  TrieTree(this.root);
  TrieNode root;
  List<int>? skips;

  bool check(final String targetStr) {
    final target = targetStr.codeUnits;
    var index = 0;
    final length = target.length;
    for (; index < length;) {
      var current = root;
      for (var i = index; i < length; i++) {
        final char = target[i];
        final tmpNode = current.find(char);
        if (tmpNode != null) {
          current = tmpNode;
          if (current.done) {
            return true;
          }
        } else {
          break;
        }
      }
      index++;
    }

    return false;
  }
}

class TrieNode {
  TrieNode({
    this.done = false,
  });
  Map<int, TrieNode> children = {};
  bool done;

  void insertWord(final List<int> word, final List<int> skips) {
    var current = this;
    for (final char in word) {
      current = current.findOrCreate(char, skips);
    }
    current.done = true;
  }

  TrieNode? find(final int char) {
    return children[char];
  }

  TrieNode findOrCreate(final int char, final List<int> skips) {
    var child = children[char];
    if (child == null) {
      child = TrieNode();

      children[char] = child;
      for (final skip in skips) {
        children[skip] = child;
      }
    }
    return child;
  }
}
