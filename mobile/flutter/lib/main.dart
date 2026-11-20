import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
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
  Auction({required this.id, required this.product, required this.description, required this.quantity, required this.unit, required this.department, required this.city, required this.sellerId, required this.seller, required this.opening, required this.closesAt, required this.privateTarget, this.closed = false, this.category='Otros', this.variety='', this.coverage='Municipio', this.allowedDepartments='', this.harvestDate='', this.priceBasis='Todo el lote', this.photoPath='', this.increment=100000, this.inactivityMinutes=10, List<String>? bundleItems, List<AuctionBid>? bids}) : bids = bids ?? [], bundleItems=bundleItems ?? [];
  final String id, product, description, unit, department, city, sellerId, seller, category, variety, coverage, allowedDepartments, harvestDate, priceBasis, photoPath;
  final int increment, inactivityMinutes;
  final List<String> bundleItems;
  final double quantity;
  final int opening, privateTarget;
  final DateTime closesAt;
  bool closed;
  final List<AuctionBid> bids;
  int get current => bids.isEmpty ? opening : bids.map((b) => b.amount).reduce((a, b) => a > b ? a : b);
  int get participants => bids.map((b) => b.userId).toSet().length;
  List<AuctionBid> get ranked { final best=<String,AuctionBid>{}; for(final b in bids){final old=best[b.userId];if(old==null||b.amount>old.amount)best[b.userId]=b;} return best.values.toList()..sort((a,b)=>b.amount.compareTo(a.amount)); }
  Map<String, dynamic> toJson() => {'id':id,'product':product,'description':description,'quantity':quantity,'unit':unit,'department':department,'city':city,'sellerId':sellerId,'seller':seller,'opening':opening,'closesAt':closesAt.toIso8601String(),'privateTarget':privateTarget,'closed':closed,'category':category,'variety':variety,'coverage':coverage,'allowedDepartments':allowedDepartments,'harvestDate':harvestDate,'priceBasis':priceBasis,'photoPath':photoPath,'increment':increment,'inactivityMinutes':inactivityMinutes,'bundleItems':bundleItems,'bids':bids.map((b)=>b.toJson()).toList()};
  factory Auction.fromJson(Map<String, dynamic> j) => Auction(id:'${j['id']}',product:'${j['product']}',description:'${j['description']}',quantity:(j['quantity'] as num).toDouble(),unit:'${j['unit']}',department:'${j['department']}',city:'${j['city']}',sellerId:'${j['sellerId']}',seller:'${j['seller']}',opening:j['opening'] as int,closesAt:DateTime.parse(j['closesAt'] as String),privateTarget:j['privateTarget'] as int,closed:j['closed'] as bool? ?? false,category:j['category'] as String? ?? 'Otros',variety:j['variety'] as String? ?? '',coverage:j['coverage'] as String? ?? 'Municipio',allowedDepartments:j['allowedDepartments'] as String? ?? '',harvestDate:j['harvestDate'] as String? ?? '',priceBasis:j['priceBasis'] as String? ?? 'Todo el lote',photoPath:j['photoPath'] as String? ?? '',increment:j['increment'] as int? ?? 100000,inactivityMinutes:j['inactivityMinutes'] as int? ?? 10,bundleItems:(j['bundleItems'] as List? ?? []).map((x)=>'$x').toList(),bids:(j['bids'] as List? ?? []).map((x)=>AuctionBid.fromJson(Map<String,dynamic>.from(x as Map))).toList());
}

class MarketUser {
  MarketUser(this.id, this.name, this.username, this.role, this.city, this.department, this.tokens, {this.photoPath='' });
  final String id, name, username, role, city, department, photoPath;
  int tokens;
  Map<String, dynamic> toJson() => {'id':id,'name':name,'username':username,'role':role,'city':city,'department':department,'tokens':tokens,'photoPath':photoPath};
  factory MarketUser.fromJson(Map<String, dynamic> j) => MarketUser('${j['id']}','${j['name']}','${j['username']}','${j['role']}','${j['city']}','${j['department']}',j['tokens'] as int? ?? 3,photoPath:j['photoPath'] as String? ?? '');
}

class ChatMessage {
  ChatMessage(this.userId, this.name, this.body, this.at);
  final String userId, name, body;
  final DateTime at;
  Map<String, dynamic> toJson() => {'userId': userId, 'name': name, 'body': body, 'at': at.toIso8601String()};
  factory ChatMessage.fromJson(Map<String, dynamic> j) => ChatMessage('${j['userId']}', '${j['name']}', '${j['body']}', DateTime.parse(j['at'] as String));
}

class DemoChat {
  DemoChat(this.auctionId, this.otherUserId, this.otherName, [List<ChatMessage>? messages]) : messages = messages ?? [];
  final String auctionId, otherUserId, otherName;
  final List<ChatMessage> messages;
  Map<String, dynamic> toJson() => {'auctionId': auctionId, 'otherUserId': otherUserId, 'otherName': otherName, 'messages': messages.map((m) => m.toJson()).toList()};
  factory DemoChat.fromJson(Map<String, dynamic> j) => DemoChat('${j['auctionId']}', '${j['otherUserId']}', '${j['otherName']}', (j['messages'] as List? ?? []).map((x) => ChatMessage.fromJson(Map<String, dynamic>.from(x as Map))).toList());
}

class TokenTransaction {
  TokenTransaction(this.label, this.tokens, this.amount, this.method, this.at);
  final String label, method;
  final int tokens, amount;
  final DateTime at;
  Map<String, dynamic> toJson() => {'label': label, 'tokens': tokens, 'amount': amount, 'method': method, 'at': at.toIso8601String()};
  factory TokenTransaction.fromJson(Map<String, dynamic> j) => TokenTransaction('${j['label']}', j['tokens'] as int, j['amount'] as int, '${j['method']}', DateTime.parse(j['at'] as String));
}

class MarketStore extends ChangeNotifier {
  static const _key = 'subastas_native_demo_v1';
  bool ready = false;
  MarketUser? user;
  List<MarketUser> users = [];
  List<Auction> auctions = [];
  final Set<String> entered = {};
  final Set<String> favorites = {};
  final List<DemoChat> chats = [];
  final List<TokenTransaction> tokenTransactions = [];
  final Set<String> deliveredAuctions = {};
  final Set<String> reviewedAuctions = {};
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
        favorites.addAll((j['favorites'] as List? ?? []).map((x) => '$x'));
        chats.addAll((j['chats'] as List? ?? []).map((x) => DemoChat.fromJson(Map<String,dynamic>.from(x as Map))));
        tokenTransactions.addAll((j['tokenTransactions'] as List? ?? []).map((x) => TokenTransaction.fromJson(Map<String,dynamic>.from(x as Map))));
        deliveredAuctions.addAll((j['delivered'] as List? ?? []).map((x) => '$x'));
        reviewedAuctions.addAll((j['reviewed'] as List? ?? []).map((x) => '$x'));
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
      Auction(id:'demo-cafe',product:'Café de origen',description:'Café tostado artesanal, notas dulces. Muestra disponible para coordinar.',quantity:25,unit:'kg',department:'Tolima',city:'Planadas',sellerId:'seller-demo',seller:'Finca El Mirador',category:'Café',opening:18000,closesAt:now.add(const Duration(days:1,hours:4)),privateTarget:45000,coverage:'Nacional',bids:[AuctionBid('buyer-a','Café Andino',26000,now.subtract(const Duration(minutes:11))),AuctionBid('buyer-b','Tienda La Plaza',31000,now.subtract(const Duration(minutes:3)))]),
      Auction(id:'demo-honey',product:'Miel de abejas',description:'Cosecha local envasada. El vendedor y comprador coordinan entrega y pago.',quantity:12,unit:'frascos',department:'Tolima',city:'Ibagué',sellerId:'seller-demo-2',seller:'Apiario La Esperanza',category:'Otros',opening:12000,closesAt:now.add(const Duration(hours:8,minutes:20)),privateTarget:32000,coverage:'Nacional'),
      Auction(id:'demo-cacao',product:'Cacao seco',description:'Grano seleccionado de pequeña producción familiar.',quantity:80,unit:'kg',department:'Huila',city:'Pitalito',sellerId:'seller-demo-3',seller:'Productores del Sur',category:'Granos',opening:14500,closesAt:now.add(const Duration(days:2,hours:2)),privateTarget:38000,coverage:'Nacional'),
    ];
    _save();
  }

  Future<void> _save() async {
    await _prefs?.setString(_key, jsonEncode({'activeUserId':user?.id,'users':users.map((x)=>x.toJson()).toList(),'auctions':auctions.map((x)=>x.toJson()).toList(),'entered':entered.toList(),'favorites':favorites.toList(),'chats':chats.map((x)=>x.toJson()).toList(),'tokenTransactions':tokenTransactions.map((x)=>x.toJson()).toList(),'delivered':deliveredAuctions.toList(),'reviewed':reviewedAuctions.toList()}));
    notifyListeners();
  }
  void _expire() { var changed=false; final now=DateTime.now(); for(final a in auctions){if(!a.closed && (now.isAfter(a.closesAt) || (a.bids.isNotEmpty && a.inactivityMinutes>0 && now.difference(a.bids.last.at).inMinutes>=a.inactivityMinutes))){a.closed=true;changed=true;}} if(changed)_save(); }
  void register({required String name, required String username, required String role, required String department, required String city, String photoPath=''}) {
    final id = 'u-${DateTime.now().microsecondsSinceEpoch}';
    user = MarketUser(id,name,username,role,city,department,role=='comprador'?10:0,photoPath:photoPath);
    users.add(user!); _save();
  }
  void updateProfilePhoto(String path){final u=user;if(u==null)return;user=MarketUser(u.id,u.name,u.username,u.role,u.city,u.department,u.tokens,photoPath:path);final i=users.indexWhere((x)=>x.id==u.id);if(i>=0)users[i]=user!;_save();}
  void logout(){user=null;_save();}
  bool hasEntered(String auctionId) => entered.contains('${user?.id}:$auctionId');
  String? bid(Auction a, int amount) {
    final u=user;
    if(u==null)return 'Inicia sesión para ofertar.';
    if(u.role!='comprador')return 'Las ofertas están habilitadas para compradores.';
    if(a.closed || DateTime.now().isAfter(a.closesAt))return 'La subasta ya terminó.';
    if(amount<a.current+a.increment)return 'La oferta mínima es ${cop(a.current+a.increment)}.';
    final key='${u.id}:${a.id}';
    if(!entered.contains(key)){
      if(u.tokens<1)return 'Te quedaste sin tokens. Recarga tu saldo en Perfil para continuar.';
      u.tokens-=1; entered.add(key); tokenTransactions.insert(0,TokenTransaction('Acceso a subasta: ${a.product}',-1,0,'uso',DateTime.now()));
    }
    a.bids.add(AuctionBid(u.id,u.username.isEmpty?u.name:u.username,amount,DateTime.now()));
    if(a.privateTarget>0&&amount>=a.privateTarget) a.closed=true;
    _save(); return null;
  }
  String? publish({required String product,required String description,required double quantity,required String unit,required String department,required String city,required int opening,required int target,required DateTime closesAt,String category='Otros',String variety='',String coverage='Municipio',String allowedDepartments='',String harvestDate='',String priceBasis='Todo el lote',String photoPath='',int increment=100000,int inactivityMinutes=10,List<String> bundleItems=const[]}) {
    final u=user;if(u==null||u.role!='vendedor')return 'Publicar es gratis para perfiles de productor.';
    if(product.trim().isEmpty||quantity<=0||opening<=0||target<0||increment<1||inactivityMinutes<1||inactivityMinutes>1440)return 'Completa el producto, cantidad, oferta inicial y un incremento mínimo válido.'; if(bundleItems.isNotEmpty&&bundleItems.length<2)return 'Un paquete debe incluir al menos dos productos.';
    auctions.insert(0,Auction(id:'lot-${DateTime.now().microsecondsSinceEpoch}',product:product.trim(),description:description.trim(),quantity:quantity,unit:unit,department:department,city:city,sellerId:u.id,seller:u.username.isEmpty?u.name:u.username,opening:opening,privateTarget:target,closesAt:closesAt,category:category,variety:variety,coverage:coverage,allowedDepartments:allowedDepartments,harvestDate:harvestDate,priceBasis:priceBasis,photoPath:photoPath,increment:increment,inactivityMinutes:inactivityMinutes,bundleItems:bundleItems));_save();return null;
  }
  String? close(Auction a){if(user?.id!=a.sellerId)return 'Solo el vendedor puede cerrar esta subasta.';if(a.bids.isEmpty)return 'Necesita al menos una oferta para cerrar.';a.closed=true;_save();return null;}
  void demoRecharge(){final u=user;if(u==null||u.role!='comprador')return;u.tokens+=10;_save();}
  void toggleFavorite(Auction a) { final key='${user?.id}:${a.id}'; if(!favorites.add(key))favorites.remove(key); _save(); }
  bool isFavorite(Auction a) => favorites.contains('${user?.id}:${a.id}');
  List<Auction> get myBids => auctions.where((a)=>a.bids.any((b)=>b.userId==user?.id)).toList();
  List<Auction> get myListings => auctions.where((a)=>a.sellerId==user?.id).toList();
  List<Auction> get myFavorites => auctions.where(isFavorite).toList();
  bool isWinner(Auction a) => a.closed && a.ranked.isNotEmpty && a.ranked.first.userId==user?.id;
  bool canOpenChat(Auction a) => a.closed && (isWinner(a) || a.sellerId==user?.id) && a.bids.isNotEmpty;
  DemoChat? chatFor(Auction a) { for(final c in chats){if(c.auctionId==a.id && (c.otherUserId==user?.id || a.sellerId==user?.id)) return c;} return null; }
  DemoChat openChat(Auction a) {
    final existing=chats.where((c)=>c.auctionId==a.id).toList(); if(existing.isNotEmpty)return existing.first;
    final winner=a.ranked.first; final otherId=user?.id==a.sellerId?winner.userId:a.sellerId;
    final otherName=user?.id==a.sellerId?winner.name:a.seller;
    final chat=DemoChat(a.id,otherId,otherName); chats.add(chat); _save(); return chat;
  }
  void sendMessage(DemoChat chat, String body) { final u=user;if(u==null||body.trim().isEmpty)return;chat.messages.add(ChatMessage(u.id,u.username.isEmpty?u.name:u.username,body.trim(),DateTime.now()));_save(); }
  bool isDelivered(Auction a) => deliveredAuctions.contains('${user?.id}:${a.id}');
  bool hasReviewed(Auction a) => reviewedAuctions.contains('${user?.id}:${a.id}');
  void markDelivered(Auction a) { deliveredAuctions.add('${user?.id}:${a.id}');_save(); }
  void submitRating(Auction a, int stars, String comment) { reviewedAuctions.add('${user?.id}:${a.id}');_save(); }
  void buyDemoPackage(int tokens, int amount, String method) { final u=user;if(u==null||u.role!='comprador')return;u.tokens+=tokens;tokenTransactions.insert(0,TokenTransaction('Recarga de $tokens tokens',tokens,amount,method,DateTime.now()));_save(); }
  List<Auction> get live => auctions.where((a)=>!a.closed && a.closesAt.isAfter(DateTime.now())).toList();
  @override void dispose(){_clock?.cancel();super.dispose();}
}

class SplashScreen extends StatelessWidget { const SplashScreen({super.key}); @override Widget build(BuildContext context)=>const Scaffold(body:Center(child:CircularProgressIndicator())); }

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key,required this.store}); final MarketStore store;
  @override State<WelcomeScreen> createState()=>_WelcomeScreenState();
}
class _WelcomeScreenState extends State<WelcomeScreen>{
  String profilePhoto='';final picker=ImagePicker();
  Future<void> _pickPhoto() async {final image=await picker.pickImage(source:ImageSource.gallery,imageQuality:84,maxWidth:1200);if(image==null)return;final dir=await getApplicationDocumentsDirectory();final saved=await File(image.path).copy('${dir.path}/profile-${DateTime.now().microsecondsSinceEpoch}.jpg');if(mounted)setState(()=>profilePhoto=saved.path);}
  final name=TextEditingController(),username=TextEditingController(),department=TextEditingController(text:'Tolima'),city=TextEditingController();String role='comprador';
  @override Widget build(BuildContext context)=>Scaffold(body:SafeArea(child:Center(child:SingleChildScrollView(padding:const EdgeInsets.all(24),child:ConstrainedBox(constraints:const BoxConstraints(maxWidth:480),child:Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[
    const Icon(Icons.agriculture_rounded,size:72,color:leaf),const SizedBox(height:12),const Text('Subastas del Campo',textAlign:TextAlign.center,style:TextStyle(fontSize:30,fontWeight:FontWeight.w800,color:forest)),const SizedBox(height:8),const Text('Conectamos cosechas locales con nuevos compradores.',textAlign:TextAlign.center,style:TextStyle(color:Colors.black54)),const SizedBox(height:28),
    const Text('Empieza tu prueba en este dispositivo',style:TextStyle(fontSize:18,fontWeight:FontWeight.bold)),const SizedBox(height:12),TextField(controller:name,decoration:const InputDecoration(labelText:'Nombre o empresa',prefixIcon:Icon(Icons.person_outline))),const SizedBox(height:10),TextField(controller:username,decoration:const InputDecoration(labelText:'Nombre de usuario (opcional)',prefixIcon:Icon(Icons.alternate_email))),const SizedBox(height:10),OutlinedButton.icon(onPressed:_pickPhoto,icon:const Icon(Icons.add_a_photo),label:Text(profilePhoto.isEmpty?'Agregar foto de perfil (opcional)':'Cambiar foto de perfil')),if(profilePhoto.isNotEmpty)Padding(padding:const EdgeInsets.all(8),child:CircleAvatar(radius:42,backgroundImage:FileImage(File(profilePhoto))),),const SizedBox(height:10),DropdownButtonFormField<String>(value:role,decoration:const InputDecoration(labelText:'¿Cómo usarás la app?'),items:const[DropdownMenuItem(value:'comprador',child:Text('Quiero comprar y ofertar')),DropdownMenuItem(value:'vendedor',child:Text('Quiero vender mi cosecha'))],onChanged:(x)=>setState(()=>role=x??'comprador')),const SizedBox(height:10),TextField(controller:department,decoration:const InputDecoration(labelText:'Departamento')),const SizedBox(height:10),TextField(controller:city,decoration:const InputDecoration(labelText:'Ciudad o municipio')),const SizedBox(height:18),FilledButton.icon(onPressed:(){if(name.text.trim().isEmpty||city.text.trim().isEmpty){ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Escribe tu nombre y ciudad para continuar.')));return;}widget.store.register(name:name.text.trim(),username:username.text.trim(),role:role,department:department.text.trim(),city:city.text.trim(),photoPath:profilePhoto);},icon:const Icon(Icons.arrow_forward),label:const Padding(padding:EdgeInsets.all(12),child:Text('Entrar a la app'))),const SizedBox(height:12),const Text('Versión de demostración: tus datos quedan guardados solo en este dispositivo. No ingreses documentos ni información sensible.',textAlign:TextAlign.center,style:TextStyle(fontSize:12,color:Colors.black54)),
  ]))))));
}

class HomeScreen extends StatefulWidget { const HomeScreen({super.key,required this.store});final MarketStore store;@override State<HomeScreen> createState()=>_HomeScreenState(); }
class _HomeScreenState extends State<HomeScreen>{int tab=0,activityTab=0;final query=TextEditingController();String dept='Todos';String city='Todas';String category='Todos';String sort='Recientes';
  @override Widget build(BuildContext context){final u=widget.store.user!;final pages=[_market(context),_activity(context),_chats(context),TokenWallet(store:widget.store),_profile(context)];return Scaffold(appBar:AppBar(title:Row(children:[const Icon(Icons.eco_rounded,color:leaf),const SizedBox(width:8),const Flexible(child:Text('Subastas del Campo',style:TextStyle(fontWeight:FontWeight.bold),overflow:TextOverflow.ellipsis))]),actions:[if(u.role=='comprador')Padding(padding:const EdgeInsets.only(right:10),child:Center(child:Chip(avatar:const Icon(Icons.token,color:gold,size:18),label:Text('${u.tokens}',style:const TextStyle(fontWeight:FontWeight.bold)))))]),body:pages[tab],floatingActionButton:u.role=='vendedor'&&tab==0?FloatingActionButton.extended(onPressed:()=>setState(()=>tab=1),icon:const Icon(Icons.add),label:const Text('Publicar gratis')):null,bottomNavigationBar:NavigationBar(selectedIndex:tab,onDestinationSelected:(i)=>setState(()=>tab=i),destinations:const[NavigationDestination(icon:Icon(Icons.storefront_outlined),selectedIcon:Icon(Icons.storefront),label:'Mercado'),NavigationDestination(icon:Icon(Icons.view_list_outlined),selectedIcon:Icon(Icons.view_list),label:'Actividad'),NavigationDestination(icon:Icon(Icons.chat_bubble_outline),selectedIcon:Icon(Icons.chat_bubble),label:'Chats'),NavigationDestination(icon:Icon(Icons.token_outlined),selectedIcon:Icon(Icons.token),label:'Tokens'),NavigationDestination(icon:Icon(Icons.account_circle_outlined),selectedIcon:Icon(Icons.account_circle),label:'Perfil')]),);
  }
  Widget _market(BuildContext context){final filtered=widget.store.auctions.where((a){final q=fold(query.text);final matches=fold('${a.product} ${a.description} ${a.city} ${a.department} ${a.seller}').contains(q);return matches&&_withinAudience(a)&&(dept=='Todos'||a.department==dept)&&(city=='Todas'||a.city==city)&&(category=='Todos'||a.category==category);}).toList();if(sort=='Mayor oferta')filtered.sort((a,b)=>b.current.compareTo(a.current));if(sort=='Menor oferta')filtered.sort((a,b)=>a.current.compareTo(b.current));if(sort=='Más ofertas')filtered.sort((a,b)=>b.bids.length.compareTo(a.bids.length));if(sort=='Menos ofertas')filtered.sort((a,b)=>a.bids.length.compareTo(b.bids.length));if(sort=='Menor apertura')filtered.sort((a,b)=>a.opening.compareTo(b.opening));if(sort=='Mayor apertura')filtered.sort((a,b)=>b.opening.compareTo(a.opening));final departments=['Todos',...widget.store.auctions.map((a)=>a.department).toSet()];final cities=['Todas',...widget.store.auctions.where((a)=>dept=='Todos'||a.department==dept).map((a)=>a.city).toSet()];return ListView(padding:const EdgeInsets.fromLTRB(16,8,16,24),children:[
    Container(padding:const EdgeInsets.all(20),decoration:BoxDecoration(borderRadius:BorderRadius.circular(24),gradient:const LinearGradient(colors:[forest,Color(0xFF527C45)],begin:Alignment.topLeft,end:Alignment.bottomRight)),child:const Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text('Cosechas locales, nuevas oportunidades',style:TextStyle(color:Colors.white,fontSize:21,fontWeight:FontWeight.bold)),SizedBox(height:7),Text('Explora, compara y oferta. La entrega y el pago se coordinan directamente entre comprador y vendedor.',style:TextStyle(color:Colors.white70,height:1.35))]),),const SizedBox(height:14),TextField(controller:query,onChanged:(_)=>setState((){}),decoration:const InputDecoration(hintText:'Busca café, papa, miel…',prefixIcon:Icon(Icons.search),suffixIcon:Icon(Icons.tune))),const SizedBox(height:10),Row(children:[Expanded(child:DropdownButtonFormField<String>(value:dept,decoration:const InputDecoration(labelText:'Departamento'),items:departments.map((x)=>DropdownMenuItem(value:x,child:Text(x))).toList(),onChanged:(x)=>setState((){dept=x??'Todos';city='Todas';}))),const SizedBox(width:10),Expanded(child:DropdownButtonFormField<String>(value:city,decoration:const InputDecoration(labelText:'Ciudad'),items:cities.map((x)=>DropdownMenuItem(value:x,child:Text(x))).toList(),onChanged:(x)=>setState(()=>city=x??'Todas')))]),const SizedBox(height:10),Wrap(spacing:7,children:[for(final c in ['Todos','Café','Frutas','Granos','Otros'])ChoiceChip(label:Text(c),selected:category==c,onSelected:(_)=>setState(()=>category=c))]),const SizedBox(height:8),DropdownButtonFormField<String>(value:sort,decoration:const InputDecoration(labelText:'Ordenar'),items:const[DropdownMenuItem(value:'Recientes',child:Text('Más recientes')),DropdownMenuItem(value:'Mayor oferta',child:Text('Mayor oferta')),DropdownMenuItem(value:'Menor oferta',child:Text('Menor oferta')),DropdownMenuItem(value:'Más ofertas',child:Text('Más ofertas')),DropdownMenuItem(value:'Menos ofertas',child:Text('Menos ofertas')),DropdownMenuItem(value:'Menor apertura',child:Text('Menor precio de apertura')),DropdownMenuItem(value:'Mayor apertura',child:Text('Mayor precio de apertura'))],onChanged:(x)=>setState(()=>sort=x??'Recientes')),const SizedBox(height:16),Text('${widget.store.live.length} subastas activas',style:const TextStyle(fontSize:16,fontWeight:FontWeight.bold,color:forest)),const SizedBox(height:8),if(filtered.isEmpty)const Padding(padding:EdgeInsets.all(32),child:Text('No encontramos productos con esos filtros.')),for(final a in filtered)AuctionCard(auction:a,store:widget.store,onTap:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>AuctionScreen(auction:a,store:widget.store)))),const SizedBox(height:12),const _DemoNote(),
  ]);}
  Widget _activity(BuildContext context){final groups=[widget.store.myBids,widget.store.myListings,widget.store.myFavorites];final titles=['Mis ofertas','Mis publicaciones','Guardados'];final rows=groups[activityTab];return ListView(padding:const EdgeInsets.all(16),children:[const Text('Tu actividad',style:TextStyle(fontSize:24,fontWeight:FontWeight.bold,color:forest)),const SizedBox(height:12),SingleChildScrollView(scrollDirection:Axis.horizontal,child:Row(children:[for(var i=0;i<titles.length;i++)Padding(padding:const EdgeInsets.only(right:8),child:ChoiceChip(label:Text('${titles[i]} (${groups[i].length})'),selected:activityTab==i,onSelected:(_)=>setState(()=>activityTab=i)))])),const SizedBox(height:12),if(activityTab==0&&widget.store.user!.role!='comprador')const _InfoCard(title:'Mis ofertas',body:'El historial de pujas aparece aquí para las cuentas compradoras.'),if(rows.isEmpty)Padding(padding:const EdgeInsets.all(30),child:Text(activityTab==1&&widget.store.user!.role!='vendedor'?'Publicar está disponible para perfiles de productor.':'Todavía no tienes elementos en esta sección.',textAlign:TextAlign.center)),for(final a in rows)AuctionCard(auction:a,store:widget.store,onTap:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>AuctionScreen(auction:a,store:widget.store)))),if(activityTab==1&&widget.store.user!.role=='vendedor')FilledButton.icon(onPressed:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>PublishScreen(store:widget.store))),icon:const Icon(Icons.add),label:const Text('Crear publicación gratis'))]);}
  Widget _chats(BuildContext context){final relevant=widget.store.chats.where((c)=>widget.store.canOpenChat(widget.store.auctions.firstWhere((a)=>a.id==c.auctionId,orElse:()=>Auction(id:'',product:'',description:'',quantity:0,unit:'',department:'',city:'',sellerId:'',seller:'',opening:0,closesAt:DateTime.now(),privateTarget:0)))).toList();return ListView(padding:const EdgeInsets.all(16),children:[const Text('Conversaciones',style:TextStyle(fontSize:24,fontWeight:FontWeight.bold,color:forest)),const SizedBox(height:8),const _InfoCard(title:'Contacto directo',body:'El chat se habilita cuando la subasta termina y solo entre el vendedor y quien ganó. Los acuerdos de pago y entrega son responsabilidad de ambos.'),if(relevant.isEmpty)const Padding(padding:EdgeInsets.all(28),child:Text('Cuando ganes una subasta, podrás iniciar aquí la conversación con el vendedor.',textAlign:TextAlign.center)),for(final c in relevant)Card(child:ListTile(leading:const CircleAvatar(backgroundColor:Color(0xFFE3EDDA),child:Icon(Icons.person,color:forest)),title:Text(c.otherName),subtitle:Text(c.messages.isEmpty?'Chat habilitado después del cierre':c.messages.last.body,maxLines:1,overflow:TextOverflow.ellipsis),trailing:const Icon(Icons.chevron_right),onTap:(){final a=widget.store.auctions.firstWhere((x)=>x.id==c.auctionId);Navigator.push(context,MaterialPageRoute(builder:(_)=>ChatScreen(store:widget.store,auction:a,chat:c)));}))]);}
  Widget _profile(BuildContext context){final u=widget.store.user!;return ListView(padding:const EdgeInsets.all(16),children:[Card(child:Padding(padding:const EdgeInsets.all(20),child:Row(children:[GestureDetector(onTap:_changePhoto,child:CircleAvatar(radius:30,backgroundColor:const Color(0xFFE3EDDA),backgroundImage:u.photoPath.isNotEmpty&&File(u.photoPath).existsSync()?FileImage(File(u.photoPath)):null,child:u.photoPath.isNotEmpty&&File(u.photoPath).existsSync()?null:Icon(u.role=='vendedor'?Icons.agriculture:Icons.person,color:forest,size:30))),const SizedBox(width:14),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(u.username.isEmpty?u.name:'@${u.username}',style:const TextStyle(fontSize:20,fontWeight:FontWeight.bold)),Text('${u.role=='vendedor'?'Productor':'Comprador'} · ${u.city}, ${u.department}',style:const TextStyle(color:Colors.black54))]))])),),if(u.role=='comprador')Card(child:ListTile(leading:const Icon(Icons.token,color:leaf),title:Text('${u.tokens} tokens disponibles',style:const TextStyle(fontWeight:FontWeight.bold)),subtitle:const Text('10 tokens de cortesía al registrarte. Se consume 1 al entrar a cada subasta; después las ofertas son ilimitadas.'),trailing:TextButton(onPressed:()=>setState(()=>tab=3),child:const Text('Recargar')))),Card(child:ListTile(leading:const Icon(Icons.rule,color:leaf),title:const Text('Reglas y términos'),subtitle:const Text('Publicar es gratis. La primera oferta válida en cada subasta consume 1 token. El pago y la entrega se acuerdan directamente.'),onTap:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>const RulesScreen())))),Card(child:ListTile(leading:const Icon(Icons.verified_user_outlined,color:leaf),title:const Text('Identidad y privacidad'),subtitle:const Text('El registro de esta demo no valida cédula ni biometría. No ingreses información sensible.'))),Card(child:ListTile(leading:const Icon(Icons.help_outline,color:leaf),title:const Text('Cómo funciona'),subtitle:const Text('Publicaciones gratis para vendedores · 10 tokens de cortesía para compradores · 1 token por subasta.'),onTap:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>const RulesScreen()))),),const SizedBox(height:10),OutlinedButton.icon(onPressed:widget.store.logout,icon:const Icon(Icons.logout),label:const Text('Cerrar sesión local'))]);}
  Future<void> _changePhoto() async {final image=await ImagePicker().pickImage(source:ImageSource.gallery,imageQuality:84,maxWidth:1200);if(image==null)return;final dir=await getApplicationDocumentsDirectory();final saved=await File(image.path).copy('${dir.path}/profile-${DateTime.now().microsecondsSinceEpoch}.jpg');widget.store.updateProfilePhoto(saved.path);}
  bool _withinAudience(Auction a){final u=widget.store.user!;final dep=fold(u.department),auctionDep=fold(a.department),town=fold(u.city),auctionTown=fold(a.city);if(a.coverage=='Nacional')return true;if(a.coverage=='Departamento')return dep==auctionDep;if(a.coverage=='Departamentos elegidos')return a.allowedDepartments.split(',').map(fold).contains(dep);return dep==auctionDep&&town==auctionTown;}
  String fold(String s)=>s.toLowerCase().replaceAll(RegExp('[áàä]'),'a').replaceAll(RegExp('[éèë]'),'e').replaceAll(RegExp('[íìï]'),'i').replaceAll(RegExp('[óòö]'),'o').replaceAll(RegExp('[úùü]'),'u');
}

class AuctionCard extends StatelessWidget {const AuctionCard({super.key,required this.auction,required this.store,required this.onTap});final Auction auction;final MarketStore store;final VoidCallback onTap;
 @override Widget build(BuildContext context){final a=auction;return Card(margin:const EdgeInsets.only(bottom:12),clipBehavior:Clip.antiAlias,child:InkWell(onTap:onTap,child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Container(height:150,decoration:BoxDecoration(color:const Color(0xFFE4EBD8),image:a.photoPath.isNotEmpty&&File(a.photoPath).existsSync()?DecorationImage(image:FileImage(File(a.photoPath)),fit:BoxFit.cover):null),child:Stack(children:[if(a.photoPath.isEmpty||!File(a.photoPath).existsSync())Positioned(right:52,top:10,child:Icon(_cropIcon(a.product),size:68,color:leaf.withOpacity(.78))),Positioned(right:4,top:3,child:IconButton(onPressed:()=>store.toggleFavorite(a),icon:Icon(store.isFavorite(a)?Icons.bookmark:Icons.bookmark_border,color:forest))),Positioned(left:16,bottom:12,child:Chip(backgroundColor:Colors.white,label:Text(a.closed?'Finalizada':'EN VIVO',style:TextStyle(color:a.closed?Colors.black54:forest,fontWeight:FontWeight.bold,fontSize:11))))])),Padding(padding:const EdgeInsets.fromLTRB(16,12,16,16),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(a.product,style:const TextStyle(fontSize:19,fontWeight:FontWeight.bold)),Text('${a.quantity} ${a.unit} · ${a.city}, ${a.department}',style:const TextStyle(color:Colors.black54)),const SizedBox(height:11),Row(children:[Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[const Text('Oferta actual',style:TextStyle(fontSize:12,color:Colors.black54)),Text(cop(a.current),style:const TextStyle(fontSize:20,fontWeight:FontWeight.w800,color:forest))])),Text('${a.participants} ofertando',style:const TextStyle(fontSize:12,color:Colors.black54)),const SizedBox(width:8),const Icon(Icons.arrow_forward_ios,size:15,color:forest)])]))])));}
}

class AuctionScreen extends StatefulWidget {const AuctionScreen({super.key,required this.auction,required this.store});final Auction auction;final MarketStore store;@override State<AuctionScreen> createState()=>_AuctionScreenState();}
class _AuctionScreenState extends State<AuctionScreen>{late Timer timer;@override void initState(){super.initState();timer=Timer.periodic(const Duration(seconds:1),(_){if(mounted)setState((){});});}@override void dispose(){timer.cancel();super.dispose();}
 @override Widget build(BuildContext context){final a=widget.auction;final u=widget.store.user!;final rem=a.closesAt.difference(DateTime.now());final winner=a.ranked.isEmpty?null:a.ranked.first;final canContact=a.closed&&winner?.userId==u.id&&a.sellerId!=u.id;final party=canContact||a.sellerId==u.id;return Scaffold(appBar:AppBar(title:Text(a.product),actions:[IconButton(onPressed:()=>widget.store.toggleFavorite(a),icon:Icon(widget.store.isFavorite(a)?Icons.bookmark:Icons.bookmark_border))]),body:ListView(padding:const EdgeInsets.all(16),children:[Container(padding:const EdgeInsets.all(20),decoration:BoxDecoration(color:forest,borderRadius:BorderRadius.circular(24)),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Row(children:[const Icon(Icons.timer_outlined,color:gold),const SizedBox(width:8),Text(a.closed?'SUBASTA CERRADA':'CIERRA EN',style:const TextStyle(color:Colors.white,fontWeight:FontWeight.bold,letterSpacing:1))]),const SizedBox(height:10),Text(a.closed?'Finalizada':clock(rem),style:TextStyle(color:clockColor(rem),fontSize:32,fontWeight:FontWeight.w800)),const SizedBox(height:14),Text('Oferta actual · ${cop(a.current)}',style:const TextStyle(color:Colors.white,fontSize:17)),Text('${a.participants} personas han ofertado',style:const TextStyle(color:Colors.white70))])),const SizedBox(height:14),Card(child:Padding(padding:const EdgeInsets.all(18),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(a.product,style:const TextStyle(fontSize:23,fontWeight:FontWeight.bold)),const SizedBox(height:6),Text('${a.quantity} ${a.unit} · ${a.city}, ${a.department}'),if(a.photoPath.isNotEmpty&&File(a.photoPath).existsSync())Padding(padding:const EdgeInsets.only(top:12),child:ClipRRect(borderRadius:BorderRadius.circular(14),child:Image.file(File(a.photoPath),height:210,width:double.infinity,fit:BoxFit.cover))),const SizedBox(height:10),Text(a.description),if(a.category.isNotEmpty)Padding(padding:const EdgeInsets.only(top:8),child:Text('${a.category}${a.variety.isNotEmpty?' · ${a.variety}':''} · alcance ${a.coverage}',style:const TextStyle(color:Colors.black54))),if(a.harvestDate.isNotEmpty)Text('Cosecha/elaboración: ${a.harvestDate}',style:const TextStyle(color:Colors.black54)),if(a.allowedDepartments.isNotEmpty)Text('Departamentos: ${a.allowedDepartments}',style:const TextStyle(color:Colors.black54)),if(a.bundleItems.isNotEmpty)...[const Divider(),const Text('Paquete completo incluido',style:TextStyle(fontWeight:FontWeight.bold)),for(final item in a.bundleItems)Text('• $item')],const Divider(height:26),Text('Vende ${a.seller}',style:const TextStyle(fontWeight:FontWeight.bold)),const SizedBox(height:4),Text('Inicio ${cop(a.opening)} · ${a.bids.length} ofertas recibidas',style:const TextStyle(color:Colors.black54))]))),Card(child:Padding(padding:const EdgeInsets.all(16),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[const Text('Mejores ofertas',style:TextStyle(fontSize:17,fontWeight:FontWeight.bold)),const SizedBox(height:8),if(a.bids.length>1)BidTrend(bids:a.bids),if(a.bids.length>1)const Padding(padding:EdgeInsets.only(top:5,bottom:6),child:Text('Evolución de las ofertas registradas',style:TextStyle(fontSize:11,color:Colors.black54))),if(a.ranked.isEmpty)const Text('Aún no hay ofertas. ¡Puedes ser el primero!'),for(var i=0;i<a.ranked.take(5).length;i++)ListTile(dense:true,contentPadding:EdgeInsets.zero,leading:CircleAvatar(radius:15,backgroundColor:i==0?gold:const Color(0xFFE9EEE4),child:Text('${i+1}',style:const TextStyle(fontWeight:FontWeight.bold))),title:Text(a.ranked[i].name,maxLines:1,overflow:TextOverflow.ellipsis),trailing:Text(cop(a.ranked[i].amount),style:const TextStyle(fontWeight:FontWeight.bold,color:forest)),subtitle:Text(timeAgo(a.ranked[i].at)))]))),if(canContact)Card(color:const Color(0xFFE5F1E2),child:ListTile(leading:const Icon(Icons.celebration,color:forest),title:const Text('¡Ganaste la subasta!',style:TextStyle(fontWeight:FontWeight.bold)),subtitle:Text('El contacto de ${a.seller} queda habilitado para coordinar pago y entrega.'))),if(party&&widget.store.canOpenChat(a))FilledButton.icon(onPressed:(){final chat=widget.store.openChat(a);Navigator.push(context,MaterialPageRoute(builder:(_)=>ChatScreen(store:widget.store,auction:a,chat:chat)));},icon:const Icon(Icons.chat),label:const Text('Abrir conversación')),if(party&&a.closed&&!widget.store.isDelivered(a))OutlinedButton.icon(onPressed:()=>_confirmDelivery(context,a),icon:const Icon(Icons.task_alt),label:const Text('Confirmar entrega y acuerdo completados')),if(party&&widget.store.deliveredAuctions.contains(a.id)&&!widget.store.hasReviewed(a))FilledButton.tonalIcon(onPressed:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>RatingScreen(store:widget.store,auction:a))),icon:const Icon(Icons.star),label:const Text('Calificar contraparte')),if(a.sellerId==u.id&&!a.closed&&a.bids.isNotEmpty)FilledButton.tonal(onPressed:(){final error=widget.store.close(a);if(error!=null)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(error)));},child:const Text('Cerrar subasta y adjudicar al líder')),if(!a.closed&&u.role=='comprador')Padding(padding:const EdgeInsets.only(top:8),child:FilledButton.icon(style:FilledButton.styleFrom(padding:const EdgeInsets.symmetric(vertical:16),backgroundColor:forest,foregroundColor:Colors.white),onPressed:()=>_bid(context,a),icon:const Icon(Icons.gavel),label:Text(widget.store.hasEntered(a.id)?'Ofertar':'Ofertar · 1 token para entrar',style:const TextStyle(fontSize:17,fontWeight:FontWeight.bold)))),if(!a.closed&&u.role=='comprador'&&!widget.store.hasEntered(a.id))const Padding(padding:EdgeInsets.only(top:8),child:Text('El token se descuenta una vez en esta subasta. Después, puedes ofertar allí sin gastar más tokens.',textAlign:TextAlign.center,style:TextStyle(color:Colors.black54,fontSize:12))),const _DemoNote()]));}
 Future<void> _confirmDelivery(BuildContext context,Auction a) async {final ok=await showDialog<bool>(context:context,builder:(ctx)=>AlertDialog(title:const Text('Confirmar operación'),content:const Text('Confirma solo si ya recibiste o entregaste el producto y acordaron el pago directamente.'),actions:[TextButton(onPressed:()=>Navigator.pop(ctx,false),child:const Text('Volver')),FilledButton(onPressed:()=>Navigator.pop(ctx,true),child:const Text('Confirmar'))]));if(ok==true)widget.store.markDelivered(a);}
 Future<void> _bid(BuildContext context,Auction a)async{if(a.closed)return;final ctrl=TextEditingController(text:'${a.current+a.increment}');final amount=await showModalBottomSheet<int>(context:context,isScrollControlled:true,builder:(ctx)=>Padding(padding:EdgeInsets.fromLTRB(20,20,20,MediaQuery.of(ctx).viewInsets.bottom+20),child:Column(mainAxisSize:MainAxisSize.min,crossAxisAlignment:CrossAxisAlignment.stretch,children:[const Text('Tu oferta',style:TextStyle(fontSize:22,fontWeight:FontWeight.bold)),const SizedBox(height:8),Text('Debe superar ${cop(a.current)}'),const SizedBox(height:12),TextField(controller:ctrl,keyboardType:TextInputType.number,decoration:const InputDecoration(labelText:'Valor en pesos',prefixText:r'$ ')),const SizedBox(height:12),Wrap(spacing:8,children:[for(final x in [a.increment,a.increment*2,a.increment*3])ActionChip(label:Text('+${cop(x)}'),onPressed:()=>ctrl.text='${a.current+x}')]),const SizedBox(height:16),FilledButton(onPressed:(){final n=int.tryParse(ctrl.text.replaceAll(RegExp(r'[^0-9]'),''));if(n==null||n<a.current+a.increment){ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content:Text('La oferta debe respetar el incremento mínimo de ${cop(a.current+a.increment)}.')));return;}Navigator.pop(ctx,n);},child:const Padding(padding:EdgeInsets.all(12),child:Text('Confirmar oferta')))])));if(amount==null||!mounted)return;final error=widget.store.bid(a,amount);if(error!=null){ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(error)));}else{ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Oferta registrada en este dispositivo.')));}}
}

class PublishScreen extends StatefulWidget {const PublishScreen({super.key,required this.store});final MarketStore store;@override State<PublishScreen> createState()=>_PublishScreenState();}
class _PublishScreenState extends State<PublishScreen>{String photoPath='';final picker=ImagePicker();final product=TextEditingController(),description=TextEditingController(),quantity=TextEditingController(),dept=TextEditingController(),city=TextEditingController(),opening=TextEditingController(),target=TextEditingController(),variety=TextEditingController(),allowed=TextEditingController(),harvest=TextEditingController(),increment=TextEditingController(text:'100000'),inactivity=TextEditingController(text:'10'),bundle=TextEditingController();String unit='kg',category='Café',coverage='Municipio',priceBasis='Todo el lote';bool isBundle=false;int days=2;@override void initState(){super.initState();dept.text=widget.store.user?.department??'';city.text=widget.store.user?.city??'';}
 Future<void> _pickPhoto() async {final image=await picker.pickImage(source:ImageSource.gallery,imageQuality:84,maxWidth:1600);if(image==null)return;final dir=await getApplicationDocumentsDirectory();final ext=image.name.contains('.')?image.name.split('.').last:'jpg';final saved=await File(image.path).copy('${dir.path}/listing-${DateTime.now().microsecondsSinceEpoch}.$ext');if(mounted)setState(()=>photoPath=saved.path);}
 @override Widget build(BuildContext context)=>ListView(padding:const EdgeInsets.all(16),children:[const Text('Publica tu cosecha',style:TextStyle(fontSize:24,fontWeight:FontWeight.bold,color:forest)),const SizedBox(height:6),const Text('Publicar es gratis. Define la apertura y, si quieres, un umbral privado para cerrar antes; si no, cerrará por tiempo o inactividad.'),const SizedBox(height:16),TextField(controller:product,decoration:const InputDecoration(labelText:'Producto',hintText:'Ej. Café de origen')),const SizedBox(height:10),OutlinedButton.icon(onPressed:_pickPhoto,icon:const Icon(Icons.add_a_photo_outlined),label:Text(photoPath.isEmpty?'Agregar foto real del producto':'Cambiar foto del producto')),if(photoPath.isNotEmpty)Padding(padding:const EdgeInsets.symmetric(vertical:8),child:ClipRRect(borderRadius:BorderRadius.circular(14),child:Image.file(File(photoPath),height:180,width:double.infinity,fit:BoxFit.cover))),const SizedBox(height:10),TextField(controller:description,maxLines:3,decoration:const InputDecoration(labelText:'Descripción, calidad y presentación')),const SizedBox(height:10),SwitchListTile(contentPadding:EdgeInsets.zero,title:const Text('Vender un paquete con varios productos'),subtitle:const Text('El comprador oferta por el conjunto completo.'),value:isBundle,onChanged:(x)=>setState(()=>isBundle=x)),if(isBundle)TextField(controller:bundle,maxLines:4,decoration:const InputDecoration(labelText:'Productos del paquete (uno por línea)',hintText:'Café tostado · 1 kg\nMiel · 2 frascos')),const SizedBox(height:10),DropdownButtonFormField<String>(value:category,decoration:const InputDecoration(labelText:'Tipo de cultivo o producto'),items:const['Café','Frutas','Granos','Otros'].map((x)=>DropdownMenuItem(value:x,child:Text(x))).toList(),onChanged:(x)=>setState(()=>category=x??'Otros')),const SizedBox(height:10),TextField(controller:variety,decoration:const InputDecoration(labelText:'Variedad o tipo específico')),const SizedBox(height:10),Row(children:[Expanded(child:TextField(controller:quantity,keyboardType:TextInputType.number,decoration:const InputDecoration(labelText:'Cantidad'))),const SizedBox(width:10),Expanded(child:DropdownButtonFormField<String>(value:unit,decoration:const InputDecoration(labelText:'Unidad'),items:const['kg','toneladas','unidades','cajas','arrobas'].map((x)=>DropdownMenuItem(value:x,child:Text(x))).toList(),onChanged:(x)=>setState(()=>unit=x??'kg')))]),const SizedBox(height:10),Row(children:[Expanded(child:TextField(controller:dept,decoration:const InputDecoration(labelText:'Departamento'))),const SizedBox(width:10),Expanded(child:TextField(controller:city,decoration:const InputDecoration(labelText:'Ciudad/municipio')))]),const SizedBox(height:10),Row(children:[Expanded(child:TextField(controller:opening,keyboardType:TextInputType.number,decoration:const InputDecoration(labelText:'Oferta inicial',prefixText:r'$ '))),const SizedBox(width:10),Expanded(child:TextField(controller:target,keyboardType:TextInputType.number,decoration:const InputDecoration(labelText:'Umbral privado opcional',prefixText:r'$ ')))]),const SizedBox(height:10),DropdownButtonFormField<String>(value:coverage,decoration:const InputDecoration(labelText:'Quién puede ver la subasta'),items:const['Municipio','Departamento','Departamentos elegidos','Nacional'].map((x)=>DropdownMenuItem(value:x,child:Text(x))).toList(),onChanged:(x)=>setState(()=>coverage=x??'Municipio')),if(coverage=='Departamentos elegidos')Padding(padding:const EdgeInsets.only(top:10),child:TextField(controller:allowed,decoration:const InputDecoration(labelText:'Departamentos incluidos',hintText:'Tolima, Huila'))),const SizedBox(height:10),TextField(controller:harvest,decoration:const InputDecoration(labelText:'Fecha de cosecha o elaboración',hintText:'Ej. octubre de 2026')),const SizedBox(height:10),DropdownButtonFormField<String>(value:priceBasis,decoration:const InputDecoration(labelText:'La oferta inicial aplica a'),items:const['Todo el lote','Por kilogramo','Por unidad o empaque'].map((x)=>DropdownMenuItem(value:x,child:Text(x))).toList(),onChanged:(x)=>setState(()=>priceBasis=x??'Todo el lote')),const SizedBox(height:10),Row(children:[Expanded(child:TextField(controller:increment,keyboardType:TextInputType.number,decoration:const InputDecoration(labelText:'Incremento mínimo',prefixText:r'$ '))),const SizedBox(width:10),Expanded(child:TextField(controller:inactivity,keyboardType:TextInputType.number,decoration:const InputDecoration(labelText:'Minutos sin pujas para cerrar')))]),const SizedBox(height:12),DropdownButtonFormField<int>(value:days,decoration:const InputDecoration(labelText:'Duración de la subasta'),items:const[1,2,3,5,7].map((x)=>DropdownMenuItem(value:x,child:Text('$x ${x==1?'día':'días'}'))).toList(),onChanged:(x)=>setState(()=>days=x??2)),const SizedBox(height:18),FilledButton.icon(onPressed:(){final error=widget.store.publish(product:product.text,description:description.text,quantity:double.tryParse(quantity.text.replaceAll(',','.'))??0,unit:unit,department:dept.text,city:city.text,opening:int.tryParse(opening.text.replaceAll(RegExp(r'[^0-9]'),''))??0,target:int.tryParse(target.text.replaceAll(RegExp(r'[^0-9]'),''))??0,closesAt:DateTime.now().add(Duration(days:days)),category:category,variety:variety.text,coverage:coverage,allowedDepartments:allowed.text,harvestDate:harvest.text,priceBasis:priceBasis,photoPath:photoPath,increment:int.tryParse(increment.text.replaceAll(RegExp(r'[^0-9]'),''))??100000,inactivityMinutes:int.tryParse(inactivity.text)??10,bundleItems:isBundle?bundle.text.split('\n').map((x)=>x.trim()).where((x)=>x.isNotEmpty).toList():const[]);if(error!=null){ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(error)));}else{ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Subasta creada gratis en este dispositivo.')));product.clear();description.clear();quantity.clear();opening.clear();target.clear();photoPath='';variety.clear();allowed.clear();harvest.clear();bundle.clear();}},icon:const Icon(Icons.add),label:const Padding(padding:EdgeInsets.all(12),child:Text('Publicar gratis'))),const SizedBox(height:14),const _DemoNote()]);}

class TokenWallet extends StatefulWidget {
  const TokenWallet({super.key, required this.store});
  final MarketStore store;
  @override State<TokenWallet> createState() => _TokenWalletState();
}
class _TokenWalletState extends State<TokenWallet> {
  String method='Nequi';
  static const packages=[(10,15000),(30,39000),(80,88000)];
  @override Widget build(BuildContext context) { final u=widget.store.user!; return ListView(padding:const EdgeInsets.all(16),children:[const Text('Mis tokens',style:TextStyle(fontSize:24,fontWeight:FontWeight.bold,color:forest)),const SizedBox(height:12),Container(padding:const EdgeInsets.all(22),decoration:BoxDecoration(gradient:const LinearGradient(colors:[forest,Color(0xFF527C45)]),borderRadius:BorderRadius.circular(22)),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[const Text('SALDO DISPONIBLE',style:TextStyle(color:Colors.white70,letterSpacing:1)),const SizedBox(height:8),Text('${u.tokens} tokens',style:const TextStyle(color:Colors.white,fontSize:32,fontWeight:FontWeight.w800)),const SizedBox(height:8),Text(u.role=='comprador'?'Un token habilita todas tus ofertas en una subasta específica.':'Como vendedor publicas gratis y no necesitas tokens.',style:const TextStyle(color:Colors.white70))]),),const SizedBox(height:18),if(u.role=='comprador')...[
    const Text('Paquetes de recarga · simulación',style:TextStyle(fontSize:18,fontWeight:FontWeight.bold)),const SizedBox(height:8),DropdownButtonFormField<String>(value:method,decoration:const InputDecoration(labelText:'Medio de pago de prueba'),items:const['Nequi','DaviPlata','PSE','Tarjeta'].map((x)=>DropdownMenuItem(value:x,child:Text(x))).toList(),onChanged:(x)=>setState(()=>method=x??'Nequi')),
    for(final p in packages)Card(child:ListTile(leading:const Icon(Icons.token,color:gold),title:Text('${p.$1} tokens',style:const TextStyle(fontWeight:FontWeight.bold)),subtitle:Text('Total simulado ${cop(p.$2)} · pago único'),trailing:FilledButton(onPressed:()=>_confirm(context,p.$1,p.$2),child:const Text('Elegir')))),const SizedBox(height:6),const _InfoCard(title:'Checkout de demostración',body:'No se abre Nequi, DaviPlata, PSE ni Wompi y no se cobra dinero real. Al confirmar, solo se acredita saldo local para probar el flujo.'),
    ] else const _InfoCard(title:'Publicar no cuesta tokens',body:'Los productores pueden crear publicaciones sin pagar. Los tokens se usan únicamente para entrar a una subasta como comprador.'),const SizedBox(height:16),const Text('Movimientos en este teléfono',style:TextStyle(fontSize:18,fontWeight:FontWeight.bold)),if(widget.store.tokenTransactions.isEmpty)const Padding(padding:EdgeInsets.all(16),child:Text('Las recargas y movimientos aparecerán aquí.')),for(final t in widget.store.tokenTransactions)Card(child:ListTile(leading:Icon(t.tokens>0?Icons.add_circle_outline:Icons.remove_circle_outline,color:t.tokens>0?leaf:Colors.orange),title:Text(t.label),subtitle:Text('${t.method} · ${t.at.toLocal().toString().substring(0,16)}'),trailing:Text(t.tokens>0?'+${t.tokens}':'${t.tokens}',style:const TextStyle(fontWeight:FontWeight.bold))))]); }
  Future<void> _confirm(BuildContext context,int tokens,int amount) async { final ok=await showDialog<bool>(context:context,builder:(ctx)=>AlertDialog(title:const Text('Checkout de prueba'),content:Text('Simular compra de $tokens tokens por ${cop(amount)} mediante $method? No se cobrará dinero.'),actions:[TextButton(onPressed:()=>Navigator.pop(ctx,false),child:const Text('Cancelar')),FilledButton(onPressed:()=>Navigator.pop(ctx,true),child:const Text('Simular aprobación'))]));if(ok==true){widget.store.buyDemoPackage(tokens,amount,method);if(mounted)ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Simulación aprobada. No se realizó ningún cobro.')));}}
}

class ChatScreen extends StatefulWidget { const ChatScreen({super.key,required this.store,required this.auction,required this.chat}); final MarketStore store; final Auction auction; final DemoChat chat; @override State<ChatScreen> createState()=>_ChatScreenState(); }
class _ChatScreenState extends State<ChatScreen> { final input=TextEditingController(); @override Widget build(BuildContext context)=>Scaffold(appBar:AppBar(title:Text(widget.chat.otherName),bottom:PreferredSize(preferredSize:const Size.fromHeight(28),child:Padding(padding:const EdgeInsets.only(bottom:8),child:Text('Acuerdo directo · ${widget.auction.product}',style:const TextStyle(fontSize:12,color:Colors.black54))))),body:Column(children:[const Padding(padding:EdgeInsets.all(10),child:_InfoCard(title:'Conexión entre las partes',body:'La plataforma solo facilita el contacto. Comprador y vendedor acuerdan pago y entrega directamente.')),Expanded(child:ListView(padding:const EdgeInsets.all(14),children:[if(widget.chat.messages.isEmpty)const Padding(padding:EdgeInsets.all(20),child:Text('Saluda y coordina los detalles de la operación.',textAlign:TextAlign.center)),for(final m in widget.chat.messages)Align(alignment:m.userId==widget.store.user?.id?Alignment.centerRight:Alignment.centerLeft,child:Container(margin:const EdgeInsets.symmetric(vertical:4),padding:const EdgeInsets.all(12),constraints:const BoxConstraints(maxWidth:300),decoration:BoxDecoration(color:m.userId==widget.store.user?.id?const Color(0xFFDCEBD7):Colors.white,borderRadius:BorderRadius.circular(16)),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(m.name,style:const TextStyle(fontWeight:FontWeight.bold,fontSize:12)),Text(m.body),Text(timeAgo(m.at),style:const TextStyle(fontSize:10,color:Colors.black45))])))])),SafeArea(child:Padding(padding:const EdgeInsets.all(10),child:Row(children:[Expanded(child:TextField(controller:input,decoration:const InputDecoration(hintText:'Escribe un mensaje'))),IconButton.filled(onPressed:(){widget.store.sendMessage(widget.chat,input.text);input.clear();setState((){});},icon:const Icon(Icons.send))])))])); @override void dispose(){input.dispose();super.dispose();} }

class RulesScreen extends StatelessWidget { const RulesScreen({super.key}); @override Widget build(BuildContext context)=>Scaffold(appBar:AppBar(title:const Text('Reglas de la plataforma')),body:ListView(padding:const EdgeInsets.all(18),children:const[Text('Subastas del Campo',style:TextStyle(fontSize:24,fontWeight:FontWeight.bold,color:forest)),SizedBox(height:12),_InfoCard(title:'Vendedores',body:'Publicar cosechas o productos es gratuito. La publicación puede ofrecer un solo producto o un conjunto; si es un conjunto, la oferta aplica a todo el paquete.'),_InfoCard(title:'Compradores y tokens',body:'Al realizar la primera oferta válida en una subasta se consume exactamente 1 token. Luego las ofertas en esa misma subasta no tienen un costo adicional. Los tokens consumidos no se reembolsan por participar.'),_InfoCard(title:'Cierre y adjudicación',body:'La subasta termina cuando se cumple la regla de cierre configurada. El vendedor y el comprador ganador coordinan directamente el pago y la entrega; la plataforma no recibe ni retiene el dinero del producto.'),_InfoCard(title:'Alcance y logística',body:'El vendedor puede limitar dónde se muestra una subasta. La plataforma no ofrece ni garantiza transporte, almacenamiento, calidad ni cumplimiento de pago/entrega.'),_InfoCard(title:'Estado de demostración',body:'Esta versión almacena datos en el dispositivo. El checkout es simulado y no verifica identidad. Estas reglas son una explicación de la demo, no sustituyen los términos legales finales del servicio.') ])); }

class RatingScreen extends StatefulWidget { const RatingScreen({super.key,required this.store,required this.auction});final MarketStore store;final Auction auction;@override State<RatingScreen> createState()=>_RatingScreenState(); }
class _RatingScreenState extends State<RatingScreen> { int score=5;final comment=TextEditingController();@override Widget build(BuildContext context){final buyer=widget.store.user?.role=='comprador';return Scaffold(appBar:AppBar(title:const Text('Calificar operación')),body:ListView(padding:const EdgeInsets.all(20),children:[Text(widget.auction.product,style:const TextStyle(fontSize:22,fontWeight:FontWeight.bold,color:forest)),const SizedBox(height:8),Text(buyer?'Evalúa la exactitud de la cantidad y si la calidad coincidió con lo publicado.':'Evalúa el pago del monto acordado y el cumplimiento logístico.'),const SizedBox(height:22),Center(child:Wrap(spacing:3,children:[for(var i=1;i<=5;i++)IconButton(onPressed:()=>setState(()=>score=i),icon:Icon(i<=score?Icons.star:Icons.star_border,color:gold,size:38))])),Center(child:Text('$score de 5 estrellas',style:const TextStyle(fontWeight:FontWeight.bold))),const SizedBox(height:18),TextField(controller:comment,maxLines:4,decoration:InputDecoration(labelText:score<=3?'Comentario obligatorio':'Comentario (opcional)',hintText:'Describe brevemente tu experiencia')),const SizedBox(height:8),if(score<=3)const Text('Para calificaciones de 3 estrellas o menos, explica el motivo.',style:TextStyle(color:Colors.deepOrange)),const _InfoCard(title:'Revisión de reportes',body:'Los reportes de faltas graves deben revisarse con soportes por una persona. Esta demo no bloquea cuentas ni verifica documentos.'),const SizedBox(height:16),FilledButton(onPressed:(){if(score<=3&&comment.text.trim().isEmpty){ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Agrega un comentario para continuar.')));return;}widget.store.submitRating(widget.auction,score,comment.text.trim());Navigator.pop(context);},child:const Padding(padding:EdgeInsets.all(13),child:Text('Enviar calificación')))]));}@override void dispose(){comment.dispose();super.dispose();} }

class _InfoCard extends StatelessWidget { const _InfoCard({required this.title,required this.body}); final String title,body; @override Widget build(BuildContext context)=>Card(child:Padding(padding:const EdgeInsets.all(15),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(title,style:const TextStyle(fontWeight:FontWeight.bold,color:forest)),const SizedBox(height:5),Text(body,style:const TextStyle(height:1.35,color:Colors.black54))]))); }

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
Color clockColor(Duration d){if(d.inHours<1)return const Color(0xFFFF6B5F);if(d.inHours<6)return const Color(0xFFFFC857);if(d.inHours<24)return const Color(0xFFB5D96C);return const Color(0xFF78D7A1);}
String clock(Duration d){if(d.isNegative)return '00:00:00';final days=d.inDays;final hours=d.inHours%24;final min=d.inMinutes%60;final sec=d.inSeconds%60;return '${days>0?'${days}d ':''}${hours.toString().padLeft(2,'0')}:${min.toString().padLeft(2,'0')}:${sec.toString().padLeft(2,'0')}';}
String timeAgo(DateTime d){final minutes=DateTime.now().difference(d).inMinutes;if(minutes<1)return 'hace unos segundos';if(minutes<60)return 'hace $minutes min';return 'hace ${minutes~/60} h';}
