import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dio/dio.dart';
import 'package:farmmarket/services/supabase_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AiChatScreen extends StatefulWidget {
  const AiChatScreen({super.key});

  @override
  State<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends State<AiChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<Map<String, String>> _messages = [];
  bool _sending = false;
  DateTime? _lastRequestAt;
  static const Duration _minInterval = Duration(seconds: 3);
  bool _showFaq = true;
  // Track expanded answers
  final Set<String> _expandedFaq = {};
  // Consumer-focused FAQs
  final List<Map<String, String>> _consumerFaq = const [
    {
      'q': 'What vegetables are available today?',
      'a': 'You can check the latest vegetables, their prices and stock in the marketplace or ask me "Show vegetables available today".',
    },
    {
      'q': 'What is the price of tomatoes near me?',
      'a': 'Ask me "Price of tomatoes". I will list items with ₹/unit and pickup address based on nearby sellers.',
    },
    {
      'q': 'How can I track my order?',
      'a': 'Go to Orders → Order Tracking to see status timeline, acceptance/rejections and delivery updates.',
    },
    {
      'q': 'Do you charge any platform fees?',
      'a': 'A small platform fee is applied at checkout based on your cart quantity. It helps keep the service running.',
    },
    {
      'q': 'Can I pick up directly from the farmer?',
      'a': 'Yes. Many items include a pickup address. You can coordinate directly with the farmer after ordering.',
    },
    {
      'q': 'How do I know freshness and stock?',
      'a': 'Each product shows freshness info and available stock. For fast updates, ask me about a product and I will fetch live data.',
    },
  ];
  // Farmer-focused FAQs
  final List<Map<String, String>> _farmerFaq = const [
    {
      'q': 'How do I list a new product?',
      'a': 'Open the marketplace management section and add product name, price (₹/unit), unit, stock and pickup location.',
    },
    {
      'q': 'How can I update stock quickly?',
      'a': 'Edit the product and change the stock number. Buyers will see the update instantly in the catalog.',
    },
    {
      'q': 'How are platform fees applied?',
      'a': 'Platform fees are charged to the buyer based on their cart quantity. You receive the listed price per unit.',
    },
    {
      'q': 'How do I handle order acceptance or rejection?',
      'a': 'From Order Tracking, approve or reject steps. The system records time and shows clear status to the buyer.',
    },
    {
      'q': 'Can I set pickup-only orders?',
      'a': 'Yes. Provide a pickup address on the product. Buyers can coordinate collection after purchase.',
    },
    {
      'q': 'Tips to attract more buyers?',
      'a': 'Keep prices competitive, update stock daily, add clear unit labels (e.g., kg/bundle) and maintain accurate pickup timings.',
    },
  ];

  String get _apiKey => const String.fromEnvironment('AI_API_KEY');
  String get _apiBase => const String.fromEnvironment('AI_API_BASE', defaultValue: 'https://api.openai.com/v1');
  // Prefer a faster default model for responsiveness; keep better model as fallback
  String get _model {
    final raw = const String.fromEnvironment('AI_MODEL', defaultValue: 'gpt-3.5-turbo');
    return _normalizeModel(raw);
  }
  String get _fallbackModel {
    final raw = const String.fromEnvironment('AI_FALLBACK_MODEL', defaultValue: 'gpt-4o-mini');
    return _normalizeModel(raw);
  }

  String _normalizeModel(String m) {
    final s = m.trim().toLowerCase();
    const aliases = {
      'gpt3.5-turbo': 'gpt-3.5-turbo',
      'gpt-3.5': 'gpt-3.5-turbo',
      'gpt-4.o-mini': 'gpt-4o-mini',
      'gpt-4.o': 'gpt-4o',
      'gpt4o': 'gpt-4o',
      'gpt4o-mini': 'gpt-4o-mini',
    };
    return aliases[s] ?? m;
  }

  String get _chatCompletionsPath {
    final hasV1 = _apiBase.endsWith('/v1') || _apiBase.endsWith('/v1/');
    return hasV1 ? '/chat/completions' : '/v1/chat/completions';
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _sending) return;
    if (_apiKey.isEmpty) {
      // Silently ignore when API key is not set; send button will be disabled in UI.
      return;
    }
    // Lightweight cooldown to avoid hitting provider rate limits
    final now = DateTime.now();
    if (_lastRequestAt != null) {
      final diff = now.difference(_lastRequestAt!);
      if (diff < _minInterval) {
        await Future.delayed(_minInterval - diff);
      }
    }
    setState(() {
      _messages.add({'role': 'user', 'content': text});
      _sending = true;
      _controller.clear();
    });

    try {
      _lastRequestAt = DateTime.now();
      final dio = Dio(BaseOptions(baseUrl: _apiBase, headers: {
        'Authorization': 'Bearer $_apiKey',
        'Content-Type': 'application/json',
      },
      // Timeouts tuned for occasional slowness
      connectTimeout: const Duration(seconds: 20),
      receiveTimeout: const Duration(seconds: 30)));

      // Build concise data context from Supabase products
      final dataContext = await _buildDataContext(text);
      // If it's a catalog-style query, answer locally for speed
      if (_looksLikeCatalogQuery(text) && dataContext.isNotEmpty) {
        setState(() {
          _messages.add({
            'role': 'assistant',
            'content': _formatQuickCatalogAnswer(dataContext),
          });
        });
        return; // Skip remote AI call for faster response
      }

      Map<String, dynamic> bodyFor(String model) {
        final history = _messages.length > 8
            ? _messages.sublist(_messages.length - 8)
            : List<Map<String, String>>.from(_messages);
        final List<Map<String, String>> chatMessages = [
          if (dataContext.isNotEmpty)
            {
              'role': 'system',
              'content': 'You are an assistant for the Marketplace for Farmers app. Answer ONLY using the following live catalog data. If the answer is not in this data, say you could not find it. Data:\n' + dataContext,
            },
          ...history,
        ];
        return {
          'model': model,
          'messages': chatMessages
              .map((m) => {
                    'role': m['role'],
                    'content': m['content'],
                  })
              .toList(),
          'max_tokens': 256,
          'temperature': 0.2,
        };
      }

      Response res;
      int attempt = 0;
      bool usedFallback = false;
      String activeModel = _model;
      while (true) {
        try {
          res = await dio.post(_chatCompletionsPath, data: jsonEncode(bodyFor(activeModel)));
          break;
        } on DioException catch (err) {
          final code = err.response?.statusCode ?? 0;
          final isRetriableStatus = code == 429 || code == 408 || code == 502 || code == 503 || code == 504 || code == 0;
          final isRetriableType = err.type == DioExceptionType.connectionTimeout ||
              err.type == DioExceptionType.receiveTimeout ||
              err.type == DioExceptionType.sendTimeout ||
              err.type == DioExceptionType.unknown;
          if ((isRetriableStatus || isRetriableType) && attempt < 5) {
            final retryAfterHeader = err.response?.headers.value('retry-after');
            final retryAfter = int.tryParse(retryAfterHeader ?? '');
            final base = retryAfter != null ? retryAfter * 1000 : (600 * (1 << attempt));
            final jitter = math.Random().nextInt(400);
            attempt += 1;
            await Future.delayed(Duration(milliseconds: base + jitter));
            // After 3 attempts on primary, try fallback model if configured
            if (!usedFallback && attempt >= 3 && _fallbackModel.isNotEmpty && _fallbackModel != activeModel) {
              usedFallback = true;
              activeModel = _fallbackModel;
            }
            continue;
          }
          rethrow;
        }
      }

      final data = res.data;
      String reply = '';
      try {
        reply = data['choices'][0]['message']['content']?.toString() ?? '';
      } catch (_) {
        reply = data.toString();
      }
      setState(() {
        _messages.add({'role': 'assistant', 'content': reply});
      });
    } on DioException catch (e) {
      final code = e.response?.statusCode;
      String msg;
      if (code == 429) {
        msg = 'The AI service is receiving too many requests. Please try again shortly.';
      } else if (code == 408 || code == 502 || code == 503 || code == 504 || code == 0 ||
          e.type == DioExceptionType.connectionTimeout || e.type == DioExceptionType.receiveTimeout || e.type == DioExceptionType.sendTimeout || e.type == DioExceptionType.unknown) {
        msg = 'The AI service is currently unreachable. Please check your internet connection and try again in a moment.';
      } else {
        msg = 'Network error: ${e.message ?? 'request failed'}';
      }
      setState(() {
        _messages.add({'role': 'assistant', 'content': msg});
      });
    } finally {
      setState(() {
        _sending = false;
      });
      await Future.delayed(const Duration(milliseconds: 50));
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('AI Assistant', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
      ),
      body: Column(
        children: [
          // Ready-made Q&A suggestions
          if (_showFaq)
            Container(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                border: Border(
                  bottom: BorderSide(color: Colors.black.withOpacity(0.05)),
                ),
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxHeight: 280, // cap height so the page fits without overflow
                ),
                child: SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text('Quick questions', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                      ),
                      IconButton(
                        tooltip: 'Hide',
                        icon: const Icon(Icons.expand_less),
                        onPressed: () => setState(() => _showFaq = false),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  // Chip row removed: only ready Q&A below
                  const SizedBox(height: 8),
                  // Consumer FAQs (expand for answers)
                  Padding(
                    padding: const EdgeInsets.only(top: 4, bottom: 2),
                    child: Text('For Consumers', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
                  ),
                  ..._consumerFaq.map((item) {
                    final id = 'c:${item['q']}';
                    final expanded = _expandedFaq.contains(id);
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          title: Text(item['q']!, style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                          trailing: IconButton(
                            icon: Icon(expanded ? Icons.remove : Icons.add),
                            onPressed: () => setState(() {
                              if (expanded) {
                                _expandedFaq.remove(id);
                              } else {
                                _expandedFaq.add(id);
                              }
                            }),
                          ),
                          onTap: () {
                            setState(() {
                              if (expanded) {
                                _expandedFaq.remove(id);
                              } else {
                                _expandedFaq.add(id);
                              }
                            });
                          },
                        ),
                        if (expanded)
                          Padding(
                            padding: const EdgeInsets.only(left: 8, right: 8, bottom: 8),
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.surface,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(item['a']!, style: GoogleFonts.inter()),
                            ),
                          ),
                      ],
                    );
                  }),
                  // Farmer FAQs (expand for answers)
                  Padding(
                    padding: const EdgeInsets.only(top: 6, bottom: 2),
                    child: Text('For Farmers', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
                  ),
                  ..._farmerFaq.map((item) {
                    final id = 'f:${item['q']}';
                    final expanded = _expandedFaq.contains(id);
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          title: Text(item['q']!, style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                          trailing: IconButton(
                            icon: Icon(expanded ? Icons.remove : Icons.add),
                            onPressed: () => setState(() {
                              if (expanded) {
                                _expandedFaq.remove(id);
                              } else {
                                _expandedFaq.add(id);
                              }
                            }),
                          ),
                          onTap: () {
                            setState(() {
                              _messages.add({'role': 'user', 'content': item['q']!});
                            });
                            _scrollToBottom();
                          },
                        ),
                        if (expanded)
                          Padding(
                            padding: const EdgeInsets.only(left: 8, right: 8, bottom: 8),
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.surface,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(item['a']!, style: GoogleFonts.inter()),
                            ),
                          ),
                      ],
                    );
                  }),
                    ],
                  ),
                ),
              ),
            ),
          // Chat list and input removed; only ready Q&A remains
        ],
      ),
    );
  }

  Future<void> _scrollToBottom() async {
    await Future.delayed(const Duration(milliseconds: 50));
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    }
  }

  void _openProductBrowser() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.9,
          minChildSize: 0.6,
          maxChildSize: 0.95,
          builder: (context, scrollController) {
            final categories = ['All', 'Vegetables', 'Fruits', 'Grains', 'Dairy'];
            String selectedCategory = 'All';
            final searchController = TextEditingController();
            return StatefulBuilder(
              builder: (context, setModalState) {
                return Container(
                  margin: const EdgeInsets.all(12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: SafeArea(
                    top: false,
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text('Browse Products', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 18)),
                            ),
                            IconButton(
                              onPressed: () => Navigator.pop(context),
                              icon: const Icon(Icons.close),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: searchController,
                          onChanged: (_) => setModalState(() {}),
                          decoration: const InputDecoration(
                            hintText: 'Search products or farmers',
                            prefixIcon: Icon(Icons.search),
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          height: 36,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemBuilder: (context, index) {
                              final c = categories[index];
                              final selected = c == selectedCategory;
                              return InkWell(
                                onTap: () {
                                  setModalState(() {
                                    selectedCategory = c;
                                  });
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: selected ? Colors.green : Theme.of(context).colorScheme.surface,
                                    borderRadius: BorderRadius.circular(18),
                                  ),
                                  child: Text(
                                    c,
                                    style: GoogleFonts.inter(
                                      color: selected ? Colors.white : Theme.of(context).textTheme.bodyMedium?.color,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              );
                            },
                            separatorBuilder: (_, __) => const SizedBox(width: 8),
                            itemCount: categories.length,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Expanded(
                          child: StreamBuilder<List<Map<String, dynamic>>>(
                            stream: SupabaseService.streamProducts(orderByUpdatedAtDesc: true),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState == ConnectionState.waiting) {
                                return const Center(child: CircularProgressIndicator());
                              }
                              if (snapshot.hasError) {
                                return Center(child: Text('Error: ${snapshot.error}'));
                              }
                              final rows = snapshot.data ?? [];
                              final search = searchController.text.trim().toLowerCase();
                              final filtered = rows.where((row) {
                                final name = (row['name'] ?? '').toString().toLowerCase();
                                final farmer = (row['farmer_name'] ?? 'farmer').toString().toLowerCase();
                                final category = (row['category'] ?? 'All').toString();
                                final matchesSearch = search.isEmpty || name.contains(search) || farmer.contains(search);
                                final matchesCategory = selectedCategory == 'All' || category == selectedCategory;
                                return matchesSearch && matchesCategory;
                              }).toList();
                              if (filtered.isEmpty) {
                                return const Center(child: Text('No products found'));
                              }
                              return ListView.separated(
                                controller: scrollController,
                                itemCount: filtered.length,
                                separatorBuilder: (_, __) => const Divider(height: 1),
                                itemBuilder: (context, index) {
                                  final row = filtered[index];
                                  final priceNum = (row['price'] is num)
                                      ? (row['price'] as num).toDouble()
                                      : double.tryParse((row['price'] ?? '0').toString()) ?? 0.0;
                                  final stock = (row['stock'] is num) ? (row['stock'] as num).toInt() : 0;
                                  final unit = (row['unit'] ?? 'kg').toString();
                                  final address = (row['pickup_address'] ?? '').toString();
                                  return ListTile(
                                    leading: const Icon(Icons.local_grocery_store),
                                    title: Text(row['name']?.toString() ?? 'Product'),
                                    subtitle: Text('₹${priceNum.toStringAsFixed(2)} /$unit · Stock: $stock · ${address.isNotEmpty ? address : 'No pickup address'}'),
                                    onTap: () {
                                      Navigator.pop(context);
                                      setState(() {
                                        _messages.add({
                                          'role': 'assistant',
                                          'content': '${row['name']} · ₹${priceNum.toStringAsFixed(2)} /$unit · Available: $stock · ${address.isNotEmpty ? address : 'No pickup address'}',
                                        });
                                      });
                                    },
                                  );
                                },
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}

extension _AiQuickAnswers on _AiChatScreenState {
  bool _looksLikeCatalogQuery(String text) {
    final q = text.toLowerCase();
    const kws = [
      'available', 'availability', 'stock', 'in stock', 'price', 'cost',
      'how much', 'rs', '₹', 'near', 'nearby', 'location', 'pickup', 'address',
      'show', 'list', 'menu', 'catalog', 'vegetable', 'fruit', 'grains', 'dairy'
    ];
    return kws.any((k) => q.contains(k));
  }

  String _formatQuickCatalogAnswer(String dataContext) {
    // dataContext is a multi-line list built in _buildDataContext
    final lines = dataContext
        .split('\n')
        .where((l) => l.trim().isNotEmpty)
        .toList();
    if (lines.isEmpty) return 'I could not find matching products right now.';
    final take = lines.take(6).toList();
    final more = lines.length - take.length;
    final buf = StringBuffer();
    buf.writeln('Here are some matching products:');
    for (final l in take) {
      // Strip leading dash if present
      buf.writeln(l.startsWith('- ') ? l.substring(2) : l);
    }
    if (more > 0) {
      buf.writeln('…and $more more. Ask me to "show more" or search in the marketplace.');
    }
    return buf.toString().trim();
  }
}

// Build a concise, query-focused data context from Supabase for the AI
extension _AiDataContext on _AiChatScreenState {
  Future<String> _buildDataContext(String userQuery) async {
    try {
      final supa = Supabase.instance.client;
      String q = userQuery.trim();
      // Limit rows and select only necessary columns
      dynamic sel = supa
          .from('products')
          .select('id,name,price,unit,stock,category,pickup_address,latitude,longitude,farmer_name,updated_at')
          .limit(30);

      // Try to filter by name or farmer_name if there is a query
      if (q.isNotEmpty) {
        // Supabase PostgREST supports or() with ilike conditions
        sel = sel.or('name.ilike.%${q}%,farmer_name.ilike.%${q}%,category.ilike.%${q}%');
      }

      final List data = await sel; // returns List<dynamic>
      if (data.isEmpty) return '';

      final buf = StringBuffer();
      for (final row in data.cast<Map<String, dynamic>>()) {
        final name = (row['name'] ?? '').toString();
        final farmer = (row['farmer_name'] ?? 'farmer').toString();
        final price = (row['price'] is num)
            ? (row['price'] as num).toDouble()
            : double.tryParse((row['price'] ?? '0').toString()) ?? 0.0;
        final unit = (row['unit'] ?? 'kg').toString();
        final stock = (row['stock'] is num) ? (row['stock'] as num).toInt() : 0;
        final cat = (row['category'] ?? '').toString();
        final addr = (row['pickup_address'] ?? '').toString();
        final lat = (row['latitude'] ?? '').toString();
        final lon = (row['longitude'] ?? '').toString();
        buf.writeln('- Product: $name | Farmer: $farmer | Price: ₹${price.toStringAsFixed(2)} /$unit | Stock: $stock | Category: $cat | Location: ${addr.isNotEmpty ? addr : '$lat,$lon'}');
      }

      return buf.toString();
    } catch (_) {
      // If anything fails, return empty so AI falls back to generic handling
      return '';
    }
  }
}
