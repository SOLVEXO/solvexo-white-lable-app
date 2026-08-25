// lib/app/services/product_context_builder.dart

import 'package:book_store_app/app/data/services/branding_service.dart';
import 'package:book_store_app/app/modules/category/models/product_model.dart';
import 'package:get/get.dart';

class ProductContextBuilder {
  static String build(List<ProductModel> products) {
    final storeName = Get.find<BrandingService>().config.value.marketplaceName;
    final buffer = StringBuffer();
    buffer.writeln(
      'You are a helpful shopping assistant for $storeName. '
      'Be friendly, concise, and only recommend products from the catalog below.',
    );
    buffer.writeln('\nCurrent catalog:');

    for (final p in products) {
      buffer.writeln(
        '- [ID:${p.id}] "${p.name}" by ${p.sellerId} | '
        '\$${p.price} | ${p.category} | '
        'Stock: ${p.inStock ? "available" : "out of stock"}',
      );
    }

    buffer.writeln('\nRules:');
    buffer.writeln('1. Only recommend books from this catalog.');
    buffer.writeln('2. When mentioning a book, include its tag: [product:ID]');
    buffer.writeln(
      '3. If asked for something not in catalog, say so politely.',
    );

    return buffer.toString();
  }
}
