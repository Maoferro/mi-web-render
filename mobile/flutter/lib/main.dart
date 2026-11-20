import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

const forest = Color(0xFF183F32);
const leaf = Color(0xFF6F9C52);
const cream = Color(0xFFF5F4E9);
const gold = Color(0xFFF2C45C);

void main() => runApp(const FieldAuctionApp());

class FieldAuctionApp extends StatefulWidget {
  const FieldAuctionApp({super.key});
  @override
  State<FieldAuctionApp> createState() => _FieldAuctionAppState();
}

class _FieldAuctionAppState extends State<FieldAuctionApp> {
  final store = MarketStore();
  @override
  void initState() {
    super.initState();
    store.load().then((_) { if (mounted) setState(() {}); });
  }
  @override
  void dispose() { store.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: store,
    builder: (context, _) => MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Subastas del Campo',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: forest, primary: forest, secondary: gold, surface: cream),
        scaffoldBackgroundColor: cream,
        appBarTheme: const AppBarTheme(backgroundColor: cream, foregroundColor: forest, centerTitle: false),
        cardTheme: CardThemeData(color: Colors.white, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
        inputDecorationTheme: InputDecorationTheme(filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none)),
      ),
      home: store.ready ? (store.user == null ? WelcomeScreen(store: store) : HomeScreen(store: store)) : const SplashScreen(),
    ),
  );
}

class AuctionBid {
  AuctionBid(this.userId, this.name, this.amount, this.at);
  final String userId, name;
  final int amount;
  final DateTime at;
  Map<String, dynamic> toJson() => {'userId': userId, 'name': name, 'amount': amount, 'at': at.toIso8601String()};
  factory AuctionBid.fromJson(Map<String, dynamic> j) => AuctionBid('${j['userId']}', '${j['name']}', j['amount'] as int, DateTime.parse(j['at'] as String));
}

class Auction {
  Auction({required this.id, required this.product, required this.description, required this.quantity, required this.unit, required this.department, required this.city, required this.sellerId, required this.seller, required this.opening, required this.closesAt, required this.privateTarget, this.closed = false, List<AuctionBid>? bids}) : bids = bids ?? [];
  final String id, product, description, unit, department, city, sellerId, seller;
  final double quantity;
  final int opening, privateTarget;
  final DateTime closesAt;
  bool closed;
  final List<AuctionBid> bids;
  int get current => bids.isEmpty ? opening : bids.map((b) => b.amount).reduce((a, b) => a > b ? a : b);
  int get participants => bids.map((b) => b.userId).toSet().length;
  List<AuctionBid> get ranked => [...bids]..sort((a, b) => b.amount.compareTo(a.amount));
  Map<String, dynamic> toJson() => {'id':id,'product':product,'description':description,'quantity':quantity,'unit':unit,'department':department,'city':city,'sellerId':sellerId,'seller':seller,'opening':opening,'closesAt':closesAt.toIso8601String(),'privateTarget':privateTarget,'closed':closed,'bids':bids.map((b)=>b.toJson()).toList()};
  factory Auction.fromJson(Map<String, dynamic> j) => Auction(id:'${j['id']}',product:'${j['product']}',description:'${j['description']}',quantity:(j['quantity'] as num).toDouble(),unit:'${j['unit']}',department:'${j['department']}',city:'${j['city']}',sellerId:'${j['sellerId']}',seller:'${j['seller']}',opening:j['opening'] as int,closesAt:DateTime.parse(j['closesAt'] as String),privateTarget:j['privateTarget'] as int,closed:j['closed'] as bool? ?? false,bids:(j['bids'] as List? ?? []).map((x)=>AuctionBid.fromJson(Map<String,dynamic>.from(x as Map))).toList());
}

class MarketUser {
  MarketUser(this.id, this.name, this.username, this.role, this.city, this.department, this.tokens);
  final String id, name, username, role, city, department;
  int tokens;
  Map<String, dynamic> toJson() => {'id':id,'name':name,'username':username,'role':role,'city':city,'department':department,'tokens':tokens};
  factory MarketUser.fromJson(Map<String, dynamic> j) => MarketUser('${j['id']}','${j['name']}','${j['username']}','${j['role']}','${j['city']}','${j['department']}',j['tokens'] as int? ?? 3);
}

class MarketStore extends ChangeNotifier {
  static const _key = 'subastas_native_demo_v1';
  bool ready = false;
  MarketUser? user;
  List<MarketUser> users = [];
  List<Auction> auctions = [];
  final Set<String> entered = {};
  SharedPreferences? _prefs;
  Timer? _clock;

  Future<void> load() async {
    _prefs = await SharedPreferences.getInstance();
    final raw = _prefs!.getString(_key);
    if (raw != null) {
      try {
        final j = jsonDecode(raw) as Map<String, dynamic>;
        users = (j['users'] as List? ?? []).map((x) => MarketUser.fromJson(Map<String,dynamic>.from(x as Map))).toList();
        final id = j['activeUserId'];
        final matches = users.where((x) => x.id == id).toList();
        user = matches.isEmpty ? null : matches.first;
        auctions = (j['auctions'] as List? ?? []).map((x) => Auction.fromJson(Map<String,dynamic>.from(x as Map))).toList();
        entered.addAll((j['entered'] as List? ?? []).map((x) => '$x'));
      } catch (_) { users = []; auctions = []; }
    }
    if (auctions.isEmpty) _seed();
    ready = true;
    _clock = Timer.periodic(const Duration(seconds: 1), (_) { _expire(); notifyListeners(); });
    notifyListeners();
  }

  void _seed() {
    final now = DateTime.now();
    auctions = [
      Auction(id:'demo-cafe',product:'Café de origen',description:'Café tostado artesanal, notas dulces. Muestra disponible para coordinar.',quantity:25,unit:'kg',department:'Tolima',city:'Planadas',sellerId:'seller-demo',seller:'Finca El Mirador',opening:18000,closesAt:now.add(const Duration(days:1,hours:4)),privateTarget:45000,bids:[AuctionBid('buyer-a','Café Andino',26000,now.subtract(const Duration(minutes:11))),AuctionBid('buyer-b','Tienda La Plaza',31000,now.subtract(const Duration(minutes:3)))]),
      Auction(id:'demo-honey',product:'Miel de abejas',description:'Cosecha local envasada. El vendedor y comprador coordinan entrega y pago.',quantity:12,unit:'frascos',department:'Tolima',city:'Ibagué',sellerId:'seller-demo-2',seller:'Apiario La Esperanza',opening:12000,closesAt:now.add(const Duration(hours:8,minutes:20)),privateTarget:32000),
      Auction(id:'demo-cacao',product:'Cacao seco',description:'Grano seleccionado de pequeña producción familiar.',quantity:80,unit:'kg',department:'Huila',city:'Pitalito',sellerId:'seller-demo-3',seller:'Productores del Sur',opening:14500,closesAt:now.add(const Duration(days:2,hours:2)),privateTarget:38000),
    ];
    _save();
  }

  Future<void> _save() async {
    await _prefs?.setString(_key, jsonEncode({'activeUserId':user?.id,'users':users.map((x)=>x.toJson()).toList(),'auctions':auctions.map((x)=>x.toJson()).toList(),'entered':entered.toList()}));
    notifyListeners();
  }
  void _expire() { var changed=false; for(final a in auctions){if(!a.closed && DateTime.now().isAfter(a.closesAt)){a.closed=true;changed=true;}} if(changed)_save(); }
  void register({required String name, required String username, required String role, required String department, required String city}) {
    final id = 'u-${DateTime.now().microsecondsSinceEpoch}';
    user = MarketUser(id,name,username,role,city,department,role=='comprador'?3:0);
    users.add(user!); _save();
  }
  void logout(){user=null;_save();}
  bool hasEntered(String auctionId) => entered.contains('${user?.id}:$auctionId');
  String? bid(Auction a, int amount) {
    final u=user;
    if(u==null)return 'Inicia sesión para ofertar.';
    if(u.role!='comprador')return 'Las ofertas están habilitadas para compradores.';
    if(a.closed || DateTime.now().isAfter(a.closesAt))return 'La subasta ya terminó.';
    if(amount<=a.current)return 'Tu oferta debe superar ${cop(a.current)}.';
    final key='${u.id}:${a.id}';
    if(!entered.contains(key)){
      if(u.tokens<1)return 'Te quedaste sin tokens. Recarga tu saldo en Perfil para continuar.';
      u.tokens-=1; entered.add(key);
    }
    a.bids.add(AuctionBid(u.id,u.username.isEmpty?u.name:u.username,amount,DateTime.now()));
    if(amount>=a.privateTarget) a.closed=true;
    _save(); return null;
  }
  String? publish({required String product,required String description,required double quantity,required String unit,required String department,required String city,required int opening,required int target,required DateTime closesAt}) {
    final u=user;if(u==null||u.role!='vendedor')return 'Publicar es gratis para perfiles de productor.';
    if(product.trim().isEmpty||quantity<=0||opening<=0||target<=opening)return 'Completa los datos y define un valor de cierre mayor a la oferta inicial.';
    auctions.insert(0,Auction(id:'lot-${DateTime.now().microsecondsSinceEpoch}',product:product.trim(),description:description.trim(),quantity:quantity,unit:unit,department:department,city:city,sellerId:u.id,seller:u.username.isEmpty?u.name:u.username,opening:opening,privateTarget:target,closesAt:closesAt));_save();return null;
  }
  String? close(Auction a){if(user?.id!=a.sellerId)return 'Solo el vendedor puede cerrar esta subasta.';if(a.bids.isEmpty)return 'Necesita al menos una oferta para cerrar.';a.closed=true;_save();return null;}
  void demoRecharge(){final u=user;if(u==null||u.role!='comprador')return;u.tokens+=10;_save();}
  List<Auction> get live => auctions.where((a)=>!a.closed && a.closesAt.isAfter(DateTime.now())).toList();
  @override void dispose(){_clock?.cancel();super.dispose();}
}

class SplashScreen extends StatelessWidget { const SplashScreen({super.key}); @override Widget build(BuildContext context)=>const Scaffold(body:Center(child:CircularProgressIndicator())); }

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key,required this.store}); final MarketStore store;
  @override State<WelcomeScreen> createState()=>_WelcomeScreenState();
}
class _WelcomeScreenState extends State<WelcomeScreen>{
  final name=TextEditingController(),username=TextEditingController(),department=TextEditingController(text:'Tolima'),city=TextEditingController();String role='comprador';
  @override Widget build(BuildContext context)=>Scaffold(body:SafeArea(child:Center(child:SingleChildScrollView(padding:const EdgeInsets.all(24),child:ConstrainedBox(constraints:const BoxConstraints(maxWidth:480),child:Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[
    const Icon(Icons.agriculture_rounded,size:72,color:leaf),const SizedBox(height:12),const Text('Subastas del Campo',textAlign:TextAlign.center,style:TextStyle(fontSize:30,fontWeight:FontWeight.w800,color:forest)),const SizedBox(height:8),const Text('Conectamos cosechas locales con nuevos compradores.',textAlign:TextAlign.center,style:TextStyle(color:Colors.black54)),const SizedBox(height:28),
    const Text('Empieza tu prueba en este dispositivo',style:TextStyle(fontSize:18,fontWeight:FontWeight.bold)),const SizedBox(height:12),TextField(controller:name,decoration:const InputDecoration(labelText:'Nombre o empresa',prefixIcon:Icon(Icons.person_outline))),const SizedBox(height:10),TextField(controller:username,decoration:const InputDecoration(labelText:'Nombre de usuario (opcional)',prefixIcon:Icon(Icons.alternate_email))),const SizedBox(height:10),DropdownButtonFormField<String>(value:role,decoration:const InputDecoration(labelText:'¿Cómo usarás la app?'),items:const[DropdownMenuItem(value:'comprador',child:Text('Quiero comprar y ofertar')),DropdownMenuItem(value:'vendedor',child:Text('Quiero vender mi cosecha'))],onChanged:(x)=>setState(()=>role=x??'comprador')),const SizedBox(height:10),TextField(controller:department,decoration:const InputDecoration(labelText:'Departamento')),const SizedBox(height:10),TextField(controller:city,decoration:const InputDecoration(labelText:'Ciudad o municipio')),const SizedBox(height:18),FilledButton.icon(onPressed:(){if(name.text.trim().isEmpty||city.text.trim().isEmpty){ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Escribe tu nombre y ciudad para continuar.')));return;}widget.store.register(name:name.text.trim(),username:username.text.trim(),role:role,department:department.text.trim(),city:city.text.trim());},icon:const Icon(Icons.arrow_forward),label:const Padding(padding:EdgeInsets.all(12),child:Text('Entrar a la app'))),const SizedBox(height:12),const Text('Versión de demostración: tus datos quedan guardados solo en este dispositivo. No ingreses documentos ni información sensible.',textAlign:TextAlign.center,style:TextStyle(fontSize:12,color:Colors.black54)),
  ]))))));
}

class HomeScreen extends StatefulWidget { const HomeScreen({super.key,required this.store});final MarketStore store;@override State<HomeScreen> createState()=>_HomeScreenState(); }
class _HomeScreenState extends State<HomeScreen>{int tab=0;final query=TextEditingController();String dept='Todos';String city='Todas';String sort='Recientes';
  @override Widget build(BuildContext context){final u=widget.store.user!;final pages=[_market(context),_publish(context),_profile(context)];return Scaffold(appBar:AppBar(title:Row(children:[const Icon(Icons.eco_rounded,color:leaf),const SizedBox(width:8),const Text('Subastas del Campo',style:TextStyle(fontWeight:FontWeight.bold))]),actions:[if(u.role=='comprador')Padding(padding:const EdgeInsets.only(right:10),child:Center(child:Chip(avatar:const Icon(Icons.token,color:gold,size:18),label:Text('${u.tokens} tokens',style:const TextStyle(fontWeight:FontWeight.bold)))))]),body:pages[tab],bottomNavigationBar:NavigationBar(selectedIndex:tab,onDestinationSelected:(i)=>setState(()=>tab=i),destinations:const[NavigationDestination(icon:Icon(Icons.storefront_outlined),selectedIcon:Icon(Icons.storefront),label:'Subastas'),NavigationDestination(icon:Icon(Icons.add_circle_outline),selectedIcon:Icon(Icons.add_circle),label:'Publicar'),NavigationDestination(icon:Icon(Icons.account_circle_outlined),selectedIcon:Icon(Icons.account_circle),label:'Perfil')]),);
  }
  Widget _market(BuildContext context){final filtered=widget.store.auctions.where((a){final q=fold(query.text);final matches=fold('${a.product} ${a.description} ${a.city} ${a.department} ${a.seller}').contains(q);return matches&&(dept=='Todos'||a.department==dept)&&(city=='Todas'||a.city==city);}).toList();if(sort=='Mayor oferta')filtered.sort((a,b)=>b.current.compareTo(a.current));if(sort=='Menor oferta')filtered.sort((a,b)=>a.current.compareTo(b.current));final departments=['Todos',...widget.store.auctions.map((a)=>a.department).toSet()];final cities=['Todas',...widget.store.auctions.where((a)=>dept=='Todos'||a.department==dept).map((a)=>a.city).toSet()];return ListView(padding:const EdgeInsets.fromLTRB(16,8,16,24),children:[
    Container(padding:const EdgeInsets.all(20),decoration:BoxDecoration(borderRadius:BorderRadius.circular(24),gradient:const LinearGradient(colors:[forest,Color(0xFF527C45)],begin:Alignment.topLeft,end:Alignment.bottomRight)),child:const Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text('Cosechas locales, nuevas oportunidades',style:TextStyle(color:Colors.white,fontSize:21,fontWeight:FontWeight.bold)),SizedBox(height:7),Text('Explora, compara y oferta. La entrega y el pago se coordinan directamente entre comprador y vendedor.',style:TextStyle(color:Colors.white70,height:1.35))]),),const SizedBox(height:14),TextField(controller:query,onChanged:(_)=>setState((){}),decoration:const InputDecoration(hintText:'Busca café, papa, miel…',prefixIcon:Icon(Icons.search),suffixIcon:Icon(Icons.tune))),const SizedBox(height:10),Row(children:[Expanded(child:DropdownButtonFormField<String>(value:dept,decoration:const InputDecoration(labelText:'Departamento'),items:departments.map((x)=>DropdownMenuItem(value:x,child:Text(x))).toList(),onChanged:(x)=>setState((){dept=x??'Todos';city='Todas';}))),const SizedBox(width:10),Expanded(child:DropdownButtonFormField<String>(value:city,decoration:const InputDecoration(labelText:'Ciudad'),items:cities.map((x)=>DropdownMenuItem(value:x,child:Text(x))).toList(),onChanged:(x)=>setState(()=>city=x??'Todas')))]),const SizedBox(height:10),DropdownButtonFormField<String>(value:sort,decoration:const InputDecoration(labelText:'Ordenar'),items:const[DropdownMenuItem(value:'Recientes',child:Text('Más recientes')),DropdownMenuItem(value:'Mayor oferta',child:Text('Mayor oferta')),DropdownMenuItem(value:'Menor oferta',child:Text('Menor oferta'))],onChanged:(x)=>setState(()=>sort=x??'Recientes')),const SizedBox(height:16),Text('${widget.store.live.length} subastas activas',style:const TextStyle(fontSize:16,fontWeight:FontWeight.bold,color:forest)),const SizedBox(height:8),if(filtered.isEmpty)const Padding(padding:EdgeInsets.all(32),child:Text('No encontramos productos con esos filtros.')),for(final a in filtered)AuctionCard(auction:a,store:widget.store,onTap:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>AuctionScreen(auction:a,store:widget.store)))),const SizedBox(height:12),const _DemoNote(),
  ]);}
  Widget _publish(BuildContext context){if(widget.store.user!.role!='vendedor')return Center(child:Padding(padding:const EdgeInsets.all(26),child:Column(mainAxisSize:MainAxisSize.min,children:[const Icon(Icons.agriculture,color:leaf,size:58),const SizedBox(height:12),const Text('Publicar cosechas es gratis para productores.',textAlign:TextAlign.center,style:TextStyle(fontSize:20,fontWeight:FontWeight.bold)),const SizedBox(height:8),const Text('Cambia tu perfil a vendedor para crear una subasta en esta demostración.'),const SizedBox(height:15),FilledButton(onPressed:(){setState(()=>tab=2);},child:const Text('Ir a mi perfil'))])));return PublishScreen(store:widget.store);}
  Widget _profile(BuildContext context){final u=widget.store.user!;return ListView(padding:const EdgeInsets.all(16),children:[Card(child:Padding(padding:const EdgeInsets.all(20),child:Row(children:[CircleAvatar(radius:30,backgroundColor:const Color(0xFFE3EDDA),child:Icon(u.role=='vendedor'?Icons.agriculture:Icons.person,color:forest,size:30)),const SizedBox(width:14),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(u.username.isEmpty?u.name:'@${u.username}',style:const TextStyle(fontSize:20,fontWeight:FontWeight.bold)),Text('${u.role=='vendedor'?'Productor':'Comprador'} · ${u.city}, ${u.department}',style:const TextStyle(color:Colors.black54))]))])),),if(u.role=='comprador')Card(child:ListTile(leading:const Icon(Icons.token,color:leaf),title:Text('${u.tokens} tokens disponibles',style:const TextStyle(fontWeight:FontWeight.bold)),subtitle:const Text('La primera oferta en cada subasta consume 1 token; luego puedes ofertar allí sin gastar más.'),trailing:FilledButton(onPressed:widget.store.demoRecharge,child:const Text('+10 demo')))),Card(child:ListTile(leading:const Icon(Icons.rule,color:leaf),title:const Text('Reglas claras'),subtitle:const Text('Los productores publican gratis. En una subasta, el token da acceso a ofertar; pago y entrega se coordinan directamente entre las partes.'))),Card(child:ListTile(leading:const Icon(Icons.security,color:leaf),title:const Text('Cuenta de demostración'),subtitle:const Text('No se verifica cédula ni identidad en esta versión. No uses datos sensibles.'))),const SizedBox(height:10),OutlinedButton.icon(onPressed:widget.store.logout,icon:const Icon(Icons.logout),label:const Text('Salir de esta cuenta'))]);}
  String fold(String s)=>s.toLowerCase().replaceAll(RegExp('[áàä]'),'a').replaceAll(RegExp('[éèë]'),'e').replaceAll(RegExp('[íìï]'),'i').replaceAll(RegExp('[óòö]'),'o').replaceAll(RegExp('[úùü]'),'u');
}

class AuctionCard extends StatelessWidget {const AuctionCard({super.key,required this.auction,required this.store,required this.onTap});final Auction auction;final MarketStore store;final VoidCallback onTap;
 @override Widget build(BuildContext context){final a=auction;return Card(margin:const EdgeInsets.only(bottom:12),clipBehavior:Clip.antiAlias,child:InkWell(onTap:onTap,child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Container(height:92,color:const Color(0xFFE4EBD8),child:Stack(children:[Positioned(right:14,top:10,child:Icon(_cropIcon(a.product),size:68,color:leaf.withOpacity(.78))),Positioned(left:16,bottom:12,child:Chip(backgroundColor:Colors.white,label:Text(a.closed?'Finalizada':'EN VIVO',style:TextStyle(color:a.closed?Colors.black54:forest,fontWeight:FontWeight.bold,fontSize:11))))])),Padding(padding:const EdgeInsets.fromLTRB(16,12,16,16),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(a.product,style:const TextStyle(fontSize:19,fontWeight:FontWeight.bold)),Text('${a.quantity} ${a.unit} · ${a.city}, ${a.department}',style:const TextStyle(color:Colors.black54)),const SizedBox(height:11),Row(children:[Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[const Text('Oferta actual',style:TextStyle(fontSize:12,color:Colors.black54)),Text(cop(a.current),style:const TextStyle(fontSize:20,fontWeight:FontWeight.w800,color:forest))])),Text('${a.participants} ofertando',style:const TextStyle(fontSize:12,color:Colors.black54)),const SizedBox(width:8),const Icon(Icons.arrow_forward_ios,size:15,color:forest)])]))])));}
}

class AuctionScreen extends StatefulWidget {const AuctionScreen({super.key,required this.auction,required this.store});final Auction auction;final MarketStore store;@override State<AuctionScreen> createState()=>_AuctionScreenState();}
class _AuctionScreenState extends State<AuctionScreen>{late Timer timer;@override void initState(){super.initState();timer=Timer.periodic(const Duration(seconds:1),(_){if(mounted)setState((){});});}@override void dispose(){timer.cancel();super.dispose();}
 @override Widget build(BuildContext context){final a=widget.auction;final u=widget.store.user!;final rem=a.closesAt.difference(DateTime.now());final winner=a.ranked.isEmpty?null:a.ranked.first;final canContact=a.closed&&winner?.userId==u.id&&a.sellerId!=u.id;return Scaffold(appBar:AppBar(title:Text(a.product)),body:ListView(padding:const EdgeInsets.all(16),children:[Container(padding:const EdgeInsets.all(20),decoration:BoxDecoration(color:forest,borderRadius:BorderRadius.circular(24)),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Row(children:[const Icon(Icons.timer_outlined,color:gold),const SizedBox(width:8),Text(a.closed?'SUBASTA CERRADA':'CIERRA EN',style:const TextStyle(color:Colors.white,fontWeight:FontWeight.bold,letterSpacing:1))]),const SizedBox(height:10),Text(a.closed?'Finalizada':clock(rem),style:TextStyle(color:rem.inHours<1?const Color(0xFFFF8A65):Colors.white,fontSize:32,fontWeight:FontWeight.w800)),const SizedBox(height:14),Text('Oferta actual · ${cop(a.current)}',style:const TextStyle(color:Colors.white,fontSize:17)),Text('${a.participants} personas han ofertado',style:const TextStyle(color:Colors.white70))])),const SizedBox(height:14),Card(child:Padding(padding:const EdgeInsets.all(18),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(a.product,style:const TextStyle(fontSize:23,fontWeight:FontWeight.bold)),const SizedBox(height:6),Text('${a.quantity} ${a.unit} · ${a.city}, ${a.department}'),const SizedBox(height:10),Text(a.description),const Divider(height:26),Text('Vende ${a.seller}',style:const TextStyle(fontWeight:FontWeight.bold)),const SizedBox(height:4),Text('Inicio ${cop(a.opening)} · ${a.bids.length} ofertas recibidas',style:const TextStyle(color:Colors.black54))]))),Card(child:Padding(padding:const EdgeInsets.all(16),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[const Text('Mejores ofertas',style:TextStyle(fontSize:17,fontWeight:FontWeight.bold)),const SizedBox(height:8),if(a.bids.length>1)BidTrend(bids:a.bids),if(a.bids.length>1)const Padding(padding:EdgeInsets.only(top:5,bottom:6),child:Text('Evolución de las ofertas registradas',style:TextStyle(fontSize:11,color:Colors.black54))),if(a.ranked.isEmpty)const Text('Aún no hay ofertas. ¡Puedes ser el primero!'),for(var i=0;i<a.ranked.take(5).length;i++)ListTile(dense:true,contentPadding:EdgeInsets.zero,leading:CircleAvatar(radius:15,backgroundColor:i==0?gold:const Color(0xFFE9EEE4),child:Text('${i+1}',style:const TextStyle(fontWeight:FontWeight.bold))),title:Text(a.ranked[i].name,maxLines:1,overflow:TextOverflow.ellipsis),trailing:Text(cop(a.ranked[i].amount),style:const TextStyle(fontWeight:FontWeight.bold,color:forest)),subtitle:Text(timeAgo(a.ranked[i].at)))]))),if(canContact)Card(color:const Color(0xFFE5F1E2),child:ListTile(leading:const Icon(Icons.celebration,color:forest),title:const Text('¡Ganaste la subasta!',style:TextStyle(fontWeight:FontWeight.bold)),subtitle:Text('Contacto: ${a.seller}. Coordinen directamente pago y entrega.'))),if(a.sellerId==u.id&&!a.closed&&a.bids.isNotEmpty)FilledButton.tonal(onPressed:(){final error=widget.store.close(a);if(error!=null)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(error)));},child:const Text('Cerrar subasta y adjudicar al líder')),if(!a.closed&&u.role=='comprador')Padding(padding:const EdgeInsets.only(top:8),child:FilledButton.icon(style:FilledButton.styleFrom(padding:const EdgeInsets.symmetric(vertical:16),backgroundColor:forest,foregroundColor:Colors.white),onPressed:()=>_bid(context,a),icon:const Icon(Icons.gavel),label:Text(widget.store.hasEntered(a.id)?'Ofertar':'Ofertar · 1 token para entrar',style:const TextStyle(fontSize:17,fontWeight:FontWeight.bold)))),if(!a.closed&&u.role=='comprador'&&!widget.store.hasEntered(a.id))const Padding(padding:EdgeInsets.only(top:8),child:Text('El token se descuenta una vez en esta subasta. Después, puedes ofertar allí sin gastar más tokens.',textAlign:TextAlign.center,style:TextStyle(color:Colors.black54,fontSize:12))),const _DemoNote()]));}
 Future<void> _bid(BuildContext context,Auction a)async{if(a.closed)return;final ctrl=TextEditingController(text:'${a.current+1000}');final amount=await showModalBottomSheet<int>(context:context,isScrollControlled:true,builder:(ctx)=>Padding(padding:EdgeInsets.fromLTRB(20,20,20,MediaQuery.of(ctx).viewInsets.bottom+20),child:Column(mainAxisSize:MainAxisSize.min,crossAxisAlignment:CrossAxisAlignment.stretch,children:[const Text('Tu oferta',style:TextStyle(fontSize:22,fontWeight:FontWeight.bold)),const SizedBox(height:8),Text('Debe superar ${cop(a.current)}'),const SizedBox(height:12),TextField(controller:ctrl,keyboardType:TextInputType.number,decoration:const InputDecoration(labelText:'Valor en pesos',prefixText:r'$ ')),const SizedBox(height:12),Wrap(spacing:8,children:[for(final x in [1000,5000,10000])ActionChip(label:Text('+${cop(x)}'),onPressed:()=>ctrl.text='${a.current+x}')]),const SizedBox(height:16),FilledButton(onPressed:(){final n=int.tryParse(ctrl.text.replaceAll(RegExp(r'[^0-9]'),''));if(n==null||n<=a.current){ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content:Text('La oferta debe ser mayor a la actual.')));return;}Navigator.pop(ctx,n);},child:const Padding(padding:EdgeInsets.all(12),child:Text('Confirmar oferta')))])));if(amount==null||!mounted)return;final error=widget.store.bid(a,amount);if(error!=null){ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(error)));}else{ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Oferta registrada en este dispositivo.')));}}
}

class PublishScreen extends StatefulWidget {const PublishScreen({super.key,required this.store});final MarketStore store;@override State<PublishScreen> createState()=>_PublishScreenState();}
class _PublishScreenState extends State<PublishScreen>{final product=TextEditingController(),description=TextEditingController(),quantity=TextEditingController(),dept=TextEditingController(),city=TextEditingController(),opening=TextEditingController(),target=TextEditingController();String unit='kg';int days=2;@override void initState(){super.initState();dept.text=widget.store.user?.department??'';city.text=widget.store.user?.city??'';}
 @override Widget build(BuildContext context)=>ListView(padding:const EdgeInsets.all(16),children:[const Text('Publica tu cosecha',style:TextStyle(fontSize:24,fontWeight:FontWeight.bold,color:forest)),const SizedBox(height:6),const Text('Gratis para productores. Tú defines el precio inicial y el valor mínimo privado para aceptar.'),const SizedBox(height:16),TextField(controller:product,decoration:const InputDecoration(labelText:'Producto',hintText:'Ej. Café de origen')),const SizedBox(height:10),TextField(controller:description,maxLines:3,decoration:const InputDecoration(labelText:'Descripción, calidad y presentación')),const SizedBox(height:10),Row(children:[Expanded(child:TextField(controller:quantity,keyboardType:TextInputType.number,decoration:const InputDecoration(labelText:'Cantidad'))),const SizedBox(width:10),Expanded(child:DropdownButtonFormField<String>(value:unit,decoration:const InputDecoration(labelText:'Unidad'),items:const['kg','toneladas','unidades','cajas','arrobas'].map((x)=>DropdownMenuItem(value:x,child:Text(x))).toList(),onChanged:(x)=>setState(()=>unit=x??'kg')))]),const SizedBox(height:10),Row(children:[Expanded(child:TextField(controller:dept,decoration:const InputDecoration(labelText:'Departamento'))),const SizedBox(width:10),Expanded(child:TextField(controller:city,decoration:const InputDecoration(labelText:'Ciudad/municipio')))]),const SizedBox(height:10),Row(children:[Expanded(child:TextField(controller:opening,keyboardType:TextInputType.number,decoration:const InputDecoration(labelText:'Oferta inicial',prefixText:r'$ '))),const SizedBox(width:10),Expanded(child:TextField(controller:target,keyboardType:TextInputType.number,decoration:const InputDecoration(labelText:'Tope privado',prefixText:r'$ ')))]),const SizedBox(height:12),DropdownButtonFormField<int>(value:days,decoration:const InputDecoration(labelText:'Duración de la subasta'),items:const[1,2,3,5,7].map((x)=>DropdownMenuItem(value:x,child:Text('$x ${x==1?'día':'días'}'))).toList(),onChanged:(x)=>setState(()=>days=x??2)),const SizedBox(height:18),FilledButton.icon(onPressed:(){final error=widget.store.publish(product:product.text,description:description.text,quantity:double.tryParse(quantity.text.replaceAll(',','.'))??0,unit:unit,department:dept.text,city:city.text,opening:int.tryParse(opening.text.replaceAll(RegExp(r'[^0-9]'),''))??0,target:int.tryParse(target.text.replaceAll(RegExp(r'[^0-9]'),''))??0,closesAt:DateTime.now().add(Duration(days:days)));if(error!=null){ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(error)));}else{ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Subasta creada gratis en este dispositivo.')));product.clear();description.clear();quantity.clear();opening.clear();target.clear();}},icon:const Icon(Icons.add),label:const Padding(padding:EdgeInsets.all(12),child:Text('Publicar gratis'))),const SizedBox(height:14),const _DemoNote()]);}

class BidTrend extends StatelessWidget {
  const BidTrend({super.key, required this.bids});
  final List<AuctionBid> bids;
  @override
  Widget build(BuildContext context) => SizedBox(height: 96, width: double.infinity, child: CustomPaint(painter: _BidTrendPainter(bids)));
}

class _BidTrendPainter extends CustomPainter {
  _BidTrendPainter(this.bids);
  final List<AuctionBid> bids;
  @override
  void paint(Canvas canvas, Size size) {
    final ordered = [...bids]..sort((a, b) => a.at.compareTo(b.at));
    final values = ordered.map((b) => b.amount).toList();
    final low = values.reduce((a, b) => a < b ? a : b).toDouble();
    final high = values.reduce((a, b) => a > b ? a : b).toDouble();
    final spread = high == low ? 1.0 : high - low;
    final line = Paint()..color = leaf..strokeWidth = 3..style = PaintingStyle.stroke..strokeCap = StrokeCap.round..strokeJoin = StrokeJoin.round;
    final fill = Paint()..color = leaf.withOpacity(.12)..style = PaintingStyle.fill;
    final grid = Paint()..color = const Color(0xFFE8ECE4)..strokeWidth = 1;
    for (var i = 0; i < 3; i++) { final y = 12 + (size.height - 24) * i / 2; canvas.drawLine(Offset(0, y), Offset(size.width, y), grid); }
    final points = <Offset>[];
    for (var i = 0; i < values.length; i++) {
      final x = values.length == 1 ? size.width / 2 : size.width * i / (values.length - 1);
      final y = size.height - 12 - ((values[i] - low) / spread) * (size.height - 24);
      points.add(Offset(x, y));
    }
    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (final point in points.skip(1)) { path.lineTo(point.dx, point.dy); }
    final area = Path.from(path)..lineTo(points.last.dx, size.height)..lineTo(points.first.dx, size.height)..close();
    canvas.drawPath(area, fill); canvas.drawPath(path, line);
    final dot = Paint()..color = forest;
    for (final point in points) { canvas.drawCircle(point, 3.5, dot); }
  }
  @override
  bool shouldRepaint(covariant _BidTrendPainter oldDelegate) => true;
}

class _DemoNote extends StatelessWidget {const _DemoNote();@override Widget build(BuildContext context)=>Container(margin:const EdgeInsets.symmetric(vertical:8),padding:const EdgeInsets.all(12),decoration:BoxDecoration(color:const Color(0xFFFFF2CF),borderRadius:BorderRadius.circular(14)),child:const Row(crossAxisAlignment:CrossAxisAlignment.start,children:[Icon(Icons.info_outline,size:18,color:Color(0xFF806016)),SizedBox(width:8),Expanded(child:Text('DEMO: las ofertas y publicaciones se guardan en este teléfono y no son visibles para otras personas. No hay cobros reales ni coordinación automática. Para operar entre usuarios conectaremos Supabase.',style:TextStyle(fontSize:12,color:Color(0xFF624D19))))]));}

IconData _cropIcon(String text){final s=text.toLowerCase();if(s.contains('café')||s.contains('cafe'))return Icons.coffee_rounded;if(s.contains('miel'))return Icons.hive_rounded;if(s.contains('papa'))return Icons.grass_rounded;if(s.contains('cacao'))return Icons.spa_rounded;return Icons.agriculture_rounded;}
String cop(int n)=>'\$${n.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'),(m)=>'.')}';
String clock(Duration d){if(d.isNegative)return '00:00:00';final days=d.inDays;final hours=d.inHours%24;final min=d.inMinutes%60;final sec=d.inSeconds%60;return '${days>0?'${days}d ':''}${hours.toString().padLeft(2,'0')}:${min.toString().padLeft(2,'0')}:${sec.toString().padLeft(2,'0')}';}
String timeAgo(DateTime d){final minutes=DateTime.now().difference(d).inMinutes;if(minutes<1)return 'hace unos segundos';if(minutes<60)return 'hace $minutes min';return 'hace ${minutes~/60} h';}
