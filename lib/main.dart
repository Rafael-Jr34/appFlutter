// lib/main.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:audioplayers/audioplayers.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  const MyApp ({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Toolbox App',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: HomePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class HomePage extends StatelessWidget {
 HomePage ({super.key});
  final  List<Map<String, dynamic>> pages = [
    {'title': 'Caja', 'widget': ToolboxCover()},
    {'title': 'Género (Genderize)', 'widget': GenderPage()},
    {'title': 'Edad (Agify)', 'widget': AgifyPage()},
    {'title': 'Universidades', 'widget': UniversitiesPage()},
    {'title': 'Clima RD', 'widget': WeatherPage()},
    {'title': 'Pokémon', 'widget': PokemonPage()},
    {'title': 'WordPress News', 'widget': WordpressPage()},
    {'title': 'Acerca de', 'widget': AboutPage()},
  ];

  @override
  
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Toolbox App')),
      body: ListView(
        children: pages.map((p) => ListTile(
          title: Text(p['title'] as String),
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => p['widget'] as Widget)),
        )).toList(),
      ),
    );
  }
}

class ToolboxCover extends StatelessWidget {
  const  ToolboxCover ({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Caja de herramientas')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Esta app sirve para varias cosas', style: TextStyle(fontSize: 18)),
            SizedBox(height: 20),
            // imagen remota (ejemplo)
            CachedNetworkImage(
              imageUrl: 'https://ferremix.com.do/cdn/shop/files/T11812_grande.jpg?v=1754322637', 
              width: 300, height: 180, fit: BoxFit.cover,
              placeholder: (c, s) => CircularProgressIndicator(),
              errorWidget: (c, s, e) => Icon(Icons.build, size: 100),
            ),
          ],
        ),
      ),
    );
  }
}
class GenderPage extends StatefulWidget {
  const GenderPage ({super.key});
  @override State<StatefulWidget> createState() => _GenderPageState();
}

class _GenderPageState extends State<GenderPage>{
  final ctrl = TextEditingController();
  String? gender;
  bool loading = false;

  Future<void> checkGender(String name) async {
    setState(() { loading = true; gender = null; });
    final url = 'https://api.genderize.io/?name=${Uri.encodeComponent(name)}';
    final res = await http.get(Uri.parse(url));
    if (res.statusCode == 200) {
      final json = jsonDecode(res.body);
      setState(() {
        gender = json['gender']; // "male" / "female" / null
        loading = false;
      });
    } else {
      setState(() { loading = false; gender = 'error'; });
    }
  }

  @override Widget build(BuildContext context) {
    Color bg = Colors.white;
    if (gender == 'male') bg = Colors.blue.shade200;
    if (gender == 'female') bg = Colors.pink.shade200;

    return Scaffold(
      appBar: AppBar(title: Text('Predecir género')),
      body: Container(
        color: bg,
        padding: EdgeInsets.all(16),
        child: Column(children: [
          TextField(controller: ctrl, decoration: InputDecoration(labelText: 'Nombre')),
          SizedBox(height: 8),
          ElevatedButton(onPressed: () => checkGender(ctrl.text.trim()), child: Text('Consultar')),
          SizedBox(height: 16),
          if (loading) CircularProgressIndicator(),
          if (!loading && gender != null) Text('Género: $gender', style: TextStyle(fontSize: 18)),
        ]),
      ),
    );
  }
}

class AgifyPage extends StatefulWidget {
  const AgifyPage ({super.key});
  @override State<StatefulWidget> createState() => _AgifyState();
}

class _AgifyState extends State<AgifyPage> {
  final ctrl = TextEditingController();
  Map? data;
  bool loading = false;

  Future<void> checkAge(String name) async {
    if (name.isEmpty) return;

    setState(() {
      loading = true;
      data = null;
    });

    final url = 'https://api.agify.io/?name=${Uri.encodeComponent(name)}';

    try {
      final res = await http.get(Uri.parse(url));
      if (res.statusCode == 200) {
        setState(() {
          data = jsonDecode(res.body);
        });
      }
    } catch (e) {
      setState(() {
        data = null;
      });
    } finally {
      setState(() {
        loading = false;
      });
    }
  }

  String _categoryForAge(int age) {
    if (age < 32) return 'Joven';
    if (age < 60) return 'Adulto';
    return 'Anciano';
  }

  String _imageForCategory(String category) {
    switch (category) {
      case 'Joven':
        return 'assets/mifoto.png';
      case 'Adulto':
        return 'assets/adulto.jpg';
      default:
        return 'assets/anciano.jpg';
    }
  }

  @override
  Widget build(BuildContext context) {
    int ageValue = 0;
    String category = '';
    String imagePath = '';

    if (data != null) {
      final rawAge = data!['age'];
      ageValue = (rawAge is int) ? rawAge : int.tryParse('$rawAge') ?? 0;
      category = _categoryForAge(ageValue);
      imagePath = _imageForCategory(category);
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Edad estimada')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: ctrl,
              decoration: const InputDecoration(
                labelText: 'Nombre',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => checkAge(ctrl.text.trim()),
              child: const Text('Consultar'),
            ),
            const SizedBox(height: 20),

            if (loading) const CircularProgressIndicator(),

            if (!loading && data != null) ...[
              Text(
                'Edad estimada: $ageValue',
                style: const TextStyle(fontSize: 20),
              ),
              const SizedBox(height: 6),
              Text(
                'Estado: $category',
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 16),

              Container(
                width: 220,
                height: 220,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 8,
                      offset: Offset(0, 4),
                    )
                  ],
                  image: DecorationImage(
                    image: AssetImage(imagePath),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    ctrl.dispose();
    super.dispose();
  }
}

class UniversitiesPage extends StatefulWidget {
  const UniversitiesPage ({super.key});
  @override State<StatefulWidget> createState() => _UniversitiesState();
}
class _UniversitiesState extends State<UniversitiesPage>
{
  final ctrl = TextEditingController(text: 'Dominican Republic');
  List? results;
  bool loading = false;

  Future<void> fetchUniversities(String country) async {
    setState(() { loading = true; results = null; });
    final url = 'https://adamix.net/proxy.php?country=${Uri.encodeComponent(country)}';
    final res = await http.get(Uri.parse(url));
    if (res.statusCode == 200) {
      final json = jsonDecode(res.body);
      // la estructura devuelta por ese proxy es un array de objetos; ajusta según respuesta real
      setState(() { results = json; loading = false; });
    } else setState(() { loading = false; });
  }

  @override Widget build(BuildContext context){
    return Scaffold(
      appBar: AppBar(title: Text('Universidades por país')),
      body: Padding(
        padding: EdgeInsets.all(12),
        child: Column(children: [
          TextField(controller: ctrl, decoration: InputDecoration(labelText: 'Country (english)')),
          ElevatedButton(onPressed: () => fetchUniversities(ctrl.text.trim()), child: Text('Buscar')),
          if (loading) CircularProgressIndicator(),
          if (results != null) Expanded(child: ListView.builder(
            itemCount: results!.length,
            itemBuilder: (c, i) {
              final u = results![i];
              final name = u['name'] ?? u['university'] ?? '';
              final web = (u['web_pages'] != null && u['web_pages'].isNotEmpty) ? u['web_pages'][0] : null;
              final domain = (web != null) ? Uri.parse(web).host : '';
              return ListTile(
                title: Text(name),
                subtitle: Text(domain),
                trailing: web != null ? IconButton(icon: Icon(Icons.open_in_new), onPressed: () => launchUrl(Uri.parse(web))) : null,
              );
            },
          ))
        ]),
      ),
    );
  }
}

class WeatherPage extends StatefulWidget {
  const WeatherPage({super.key});

  @override
  State<WeatherPage> createState() => _WeatherPageState();
}

class _WeatherPageState extends State<WeatherPage> {

  Map? data;
  bool loading = false;

  Future<void> fetchWeather() async {
    setState(() => loading = true);

    final apiKey = 'key'; // pon tu API real aquí
    final url =
        'https://api.openweathermap.org/data/2.5/weather?q=Santo%20Domingo,DO&units=metric&appid=$apiKey';

    final res = await http.get(Uri.parse(url));

    if (res.statusCode == 200) {
      setState(() {
        data = jsonDecode(res.body);
      });
    }

    setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Clima RD')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ElevatedButton(
              onPressed: fetchWeather,
              child: const Text('Ver clima hoy'),
            ),
            const SizedBox(height: 20),

            if (loading) const CircularProgressIndicator(),

            if (data != null && !loading) ...[
              Text(
                'Temperatura: ${data!['main']['temp']} °C',
                style: const TextStyle(fontSize: 20),
              ),
              Text(
                'Descripción: ${data!['weather'][0]['description']}',
              ),
            ]
          ],
        ),
      ),
    );
  }
}

class PokemonPage extends StatefulWidget { 

  const PokemonPage ({super.key});
  @override
  State<PokemonPage> createState() => _PokemonState();
 }

class _PokemonState extends State<PokemonPage> {
  final ctrl = TextEditingController(text: 'pikachu');
  Map? p;
  final FlutterTts _tts = FlutterTts();
  final AudioPlayer _player = AudioPlayer();
  bool loading = false;
  bool playing = false;

  @override
  void initState() {
    super.initState();
  }

  Future<void> fetchPokemon(String name) async {
    if (name.isEmpty) return;
    setState(() {
      loading = true;
      p = null;
    });

    final url = 'https://pokeapi.co/api/v2/pokemon/${Uri.encodeComponent(name.toLowerCase())}';
    try {
      final res = await http.get(Uri.parse(url));
      if (res.statusCode == 200) {
        final json = jsonDecode(res.body);
        setState(() {
          p = json;
        });
        // opcional: reproducir TTS automáticamente (comentado)
        // await _tts.speak('Pokémon ${p!['name']}');
      } else {
        setState(() {
          p = null;
        });
        final body = res.body;
        debugPrint('PokeAPI error ${res.statusCode}: $body');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se encontró el Pokémon: ${res.statusCode}')),
        );
      }
    } catch (e) {
      debugPrint('Fetch exception: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al consultar PokeAPI')),
      );
      setState(() {
        p = null;
      });
    } finally {
      setState(() {
        loading = false;
      });
    }
  }

  /// Intenta encontrar un "cry" existente probando varias rutas conocidas.
  /// Devuelve la URL si existe, o null.
  Future<String?> _findCryUrl(int id) async {
    final candidates = <String>[
      // rutas conocidas (varian según repositorios públicos)
      // 1) PokeAPI cries repo (patrón que suele aparecer)
      'https://raw.githubusercontent.com/PokeAPI/cries/main/cries/pokemon/latest/$id.ogg',
      'https://raw.githubusercontent.com/PokeAPI/cries/main/cries/pokemon/legacy/$id.ogg',
      // 2) Otro patrón (repos antiguas)
      'https://raw.githubusercontent.com/PokeAPI/cries/master/cries/$id.wav',
      // 3) Un repositorio alternativo (por si acaso)
      'https://raw.githubusercontent.com/msikma/pokesprite/master/cries/$id.ogg',
    ];

    for (final url in candidates) {
      try {
        final head = await http.head(Uri.parse(url));
        if (head.statusCode == 200) {
          return url;
        }
      } catch (e) {
        // ignora excepciones y sigue probando
        debugPrint('HEAD error $url -> $e');
      }
    }
    return null;
  }

  Future<void> _playCryOrTts() async {
    if (p == null) return;

    final id = p!['id'] as int;
    // buscamos archivo real
    final cryUrl = await _findCryUrl(id);

    if (cryUrl != null) {
      // Reproducir con audioplayers
      try {
        // stop previo
        await _player.stop();
        setState(() { playing = true; });
        await _player.play(UrlSource(cryUrl));
        // cuando termine, actualizar estado
        _player.onPlayerComplete.listen((_) {
          setState(() { playing = false; });
        });
      } catch (e) {
        debugPrint('Error reproducir audio: $e');
        // fallback a TTS
        await _tts.speak('Pokémon ${p!['name']}');
      }
    } else {
      // fallback: pronunciar con TTS
      await _tts.speak('Pokémon ${p!['name']}');
    }
  }

  @override
  void dispose() {
    ctrl.dispose();
    _player.dispose();
    _tts.stop();
    super.dispose();
  }

  String _abilitiesText() {
    if (p == null) return '';
    final abilities = (p!['abilities'] as List).map((a) => a['ability']['name']).toList();
    return abilities.join(', ');
  }

  @override
  Widget build(BuildContext context) {
    final spriteUrl = p != null ? p!['sprites']['front_default'] as String? : null;
    final baseExp = p != null ? p!['base_experience']?.toString() ?? '' : '';
    final name = p != null ? (p!['name'] as String) : '';

    return Scaffold(
      appBar: AppBar(title: const Text('Pokémon')),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          TextField(
            controller: ctrl,
            decoration: const InputDecoration(labelText: 'Nombre Pokémon', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 8),
          ElevatedButton(onPressed: () => fetchPokemon(ctrl.text.trim()), child: const Text('Buscar')),
          const SizedBox(height: 12),

          if (loading) const Center(child: CircularProgressIndicator()),

          if (p != null && !loading) ...[
            Center(child: Text('Nombre: $name', style: const TextStyle(fontSize: 20))),
            const SizedBox(height: 6),
            Center(child: Text('Experiencia base: $baseExp')),
            const SizedBox(height: 6),
            Center(child: Text('Habilidades: ${_abilitiesText()}')),
            const SizedBox(height: 12),

            if (spriteUrl != null && spriteUrl.isNotEmpty)
              Center(
                child: CachedNetworkImage(
                  imageUrl: spriteUrl,
                  width: 140,
                  height: 140,
                  placeholder: (c, u) => const SizedBox(width: 140, height: 140, child: Center(child: CircularProgressIndicator())),
                  errorWidget: (c, u, e) => const Icon(Icons.broken_image, size: 80),
                ),
              ),

            const SizedBox(height: 12),

            // Botones de sonido
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: playing ? null : _playCryOrTts,
                  icon: const Icon(Icons.volume_up),
                  label: Text(playing ? 'Reproduciendo...' : 'Escuchar sonido'),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: () async {
                    await _player.stop();
                    setState(() { playing = false; });
                  },
                  icon: const Icon(Icons.stop),
                  label: const Text('Detener'),
                ),
              ],
            ),
          ],
        ]),
      ),
    );
  }
}

class WordpressPage extends StatefulWidget { 
  const WordpressPage ({super.key});
  @override
  State<WordpressPage> createState() => _WordpressState();
 }
// Reemplaza tu clase por esta
class _WordpressState extends State<WordpressPage> {
  // Default: puedes cambiarlo si quieres otra web (ej: 'https://www.sitepoint.com')
  final ctrl = TextEditingController(text: 'https://sitepoint.com');
  List? posts;
  String? logo;

  /// Normaliza el input para generar variantes razonables:
  List<String> _candidatesFrom(String input) {
    final raw = input.trim();
    if (raw.isEmpty) return [];

    String domain = raw;
    // quitar esquema si existe
    domain = domain.replaceFirst(RegExp(r'^https?://'), '');
    // quitar trailing slash
    if (domain.endsWith('/')) domain = domain.substring(0, domain.length - 1);

    // si viene con path (ej: site.com/news) lo conservamos como variante también
    final withPath = domain.contains('/') ? domain : null;

    final baseNoWww = domain.replaceFirst(RegExp(r'^www\.'), '');
    final variants = <String>{};

    // formas con https y sin https, con y sin www
    variants.add('https://$baseNoWww');
    variants.add('https://www.$baseNoWww');
    variants.add('http://$baseNoWww');
    variants.add('http://www.$baseNoWww');

    // si el input tenía path, prueba con esa path también (ej: site.com/news)
    if (withPath != null) {
      final path = withPath; // ya sin scheme y sin trailing slash
      variants.add('https://$path');
      variants.add('http://$path');
    }

    return variants.toList();
  }

  Future<void> fetchWP(String site) async {
    setState(() {
      posts = null;
    });

    final candidates = _candidatesFrom(site);
    if (candidates.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Introduce una URL válida')));
      return;
    }

    http.Response? lastRes;
    String? lastError;
    bool found = false;

    for (final base in candidates) {
      final postsUrl = '$base/wp-json/wp/v2/posts?per_page=3&_fields=title,excerpt,link';
      try {
        final uri = Uri.parse(postsUrl);
        final res = await http.get(uri).timeout(const Duration(seconds: 10), onTimeout: () => throw Exception('timeout'));
        lastRes = res;
        if (res.statusCode == 200) {
          // éxito: parseamos y salimos
          setState(() {
            posts = jsonDecode(res.body);
          });
          found = true;

          // intentar buscar un logo simple (no fiable para todos los temas)
          try {
            final siteJsonUrl = '$base/wp-json';
            final siteRes = await http.get(Uri.parse(siteJsonUrl)).timeout(const Duration(seconds: 6));
            if (siteRes.statusCode == 200) {
              final sj = jsonDecode(siteRes.body);
              // muchos WP no exponen logo aquí; dejamos esto como intento (puede fallar)
              if (sj is Map && sj.containsKey('site_icon')) {
                final icon = sj['site_icon'];
                if (icon is String && icon.isNotEmpty) logo = icon;
              }
            }
          } catch (_) { /* ignore */ }

          break;
        } else {
          // si devuelve 3xx/4xx/5xx, guardamos info y probamos siguiente variante
          lastError = 'HTTP ${res.statusCode}';
          debugPrint('WP try $postsUrl -> ${res.statusCode}');
        }
      } catch (e) {
        lastError = e.toString();
        debugPrint('WP try $postsUrl -> EXCEPTION: $e');
      }
    }

    if (!found) {
      // No encontramos ninguna variante válida
      final msg = lastRes != null
          ? 'No se pudo obtener posts (último status: ${lastRes.statusCode})'
          : 'No se pudo conectar. error: $lastError';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
      setState(() {
        posts = null;
      });
    } else {
      setState(() { /* posts ya seteado */ });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('WP News')),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(children: [
          TextField(controller: ctrl, decoration: const InputDecoration(labelText: 'Site URL')),
          ElevatedButton(onPressed: () => fetchWP(ctrl.text.trim()), child: const Text('Traer últimas 3')),
          const SizedBox(height: 8),
          if (posts != null)
            Expanded(child: ListView.builder(
              itemCount: posts!.length,
              itemBuilder: (c,i){
                final p = posts![i];
                final title = p['title']?['rendered'] ?? '';
                final excerpt = p['excerpt']?['rendered'] ?? '';
                final link = p['link'] ?? '';
                return Card(
                  child: ListTile(
                    leading: logo != null ? Image.network(logo!) : const Icon(Icons.rss_feed),
                    title: Text(stripHtml(title)),
                    subtitle: Text(stripHtml(excerpt), maxLines: 3, overflow: TextOverflow.ellipsis),
                    onTap: () => launchUrl(Uri.parse(link)),
                  ),
                );
              },
            )),
          if (posts == null) const SizedBox.shrink()
        ]),
      ),
    );
  }

  String stripHtml(String html) {
    return html.replaceAll(RegExp(r'<[^>]*>'), '');
  }
}

class AboutPage extends StatelessWidget {
  const AboutPage ({super.key});
  @override Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Acerca de')),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(children:[
          CircleAvatar(radius: 60, backgroundImage: AssetImage('assets/mifoto.png')),
          SizedBox(height: 12),
          Text('Rafael Junior Silfa Gómez', style: TextStyle(fontSize: 20)),
          Text('Contacto: 20240034@itla.com'),
          
        ]),
      ),
    );
  }
}