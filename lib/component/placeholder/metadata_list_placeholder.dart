import "package:flutter/material.dart";
import "package:loure/component/placeholder/metadata_placeholder.dart";

class MetadataListPlaceholder extends StatelessWidget {
  MetadataListPlaceholder({super.key, this.onRefresh});
  Function? onRefresh;

  final ScrollController _controller = ScrollController();

  @override
  Widget build(final BuildContext context) {
    return GestureDetector(
      child: RefreshIndicator(
        onRefresh: () async {
          if (onRefresh != null) {
            onRefresh!();
          }
        },
        child: ListView.builder(
          itemBuilder: (final BuildContext context, final int index) {
            return const MetadataPlaceholder();
          },
          itemCount: 10,
        ),
      ),
    );
  }
}
