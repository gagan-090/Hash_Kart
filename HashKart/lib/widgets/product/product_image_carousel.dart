import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/product_model.dart';

class ProductImageCarousel extends StatefulWidget {
  final List<ProductImage> images;
  final Function(int)? onPageChanged;

  const ProductImageCarousel({
    super.key,
    required this.images,
    this.onPageChanged,
  });

  @override
  State<ProductImageCarousel> createState() => _ProductImageCarouselState();
}

class _ProductImageCarouselState extends State<ProductImageCarousel> {
  late PageController _pageController;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final images = widget.images.isNotEmpty 
        ? widget.images 
        : [ProductImage(
            id: '1', 
            productId: '', 
            image: 'https://via.placeholder.com/400',
            createdAt: DateTime.now(),
          )];

    return Stack(
      children: [
        // Main Image Carousel
        SizedBox(
          height: 400,
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentIndex = index;
              });
              widget.onPageChanged?.call(index);
            },
            itemCount: images.length,
            itemBuilder: (context, index) {
              return GestureDetector(
                onTap: () => _showImageViewer(context, images, index),
                child: Hero(
                  tag: 'product_image_$index',
                  child: CachedNetworkImage(
                    imageUrl: images[index].image,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: 400,
                    placeholder: (context, url) => Container(
                      color: Colors.grey[200],
                      child: const Center(
                        child: CircularProgressIndicator(),
                      ),
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: Colors.grey[200],
                      child: const Icon(
                        Icons.image_not_supported,
                        size: 80,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),

        // Page Indicators
        if (images.length > 1)
          Positioned(
            bottom: 16,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: images.asMap().entries.map((entry) {
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: _currentIndex == entry.key ? 24 : 8,
                  height: 8,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    color: _currentIndex == entry.key
                        ? Colors.white
                        : Colors.white.withOpacity(0.4),
                  ),
                );
              }).toList(),
            ),
          ),

        // Zoom Icon
        Positioned(
          bottom: 16,
          right: 16,
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.5),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.zoom_in,
              color: Colors.white,
              size: 20,
            ),
          ),
        ),
      ],
    );
  }

  void _showImageViewer(BuildContext context, List<ProductImage> images, int initialIndex) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ImageViewer(
          images: images,
          initialIndex: initialIndex,
        ),
      ),
    );
  }
}

class ImageViewer extends StatefulWidget {
  final List<ProductImage> images;
  final int initialIndex;

  const ImageViewer({
    super.key,
    required this.images,
    required this.initialIndex,
  });

  @override
  State<ImageViewer> createState() => _ImageViewerState();
}

class _ImageViewerState extends State<ImageViewer> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          '${_currentIndex + 1} of ${widget.images.length}',
          style: const TextStyle(color: Colors.white),
        ),
      ),
      body: PageView.builder(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        itemCount: widget.images.length,
        itemBuilder: (context, index) {
          return InteractiveViewer(
            panEnabled: true,
            boundaryMargin: const EdgeInsets.all(20),
            minScale: 0.5,
            maxScale: 4.0,
            child: Center(
              child: Hero(
                tag: 'product_image_$index',
                child: CachedNetworkImage(
                  imageUrl: widget.images[index].image,
                  fit: BoxFit.contain,
                  placeholder: (context, url) => const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  ),
                  errorWidget: (context, url, error) => const Icon(
                    Icons.error,
                    color: Colors.white,
                    size: 80,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}