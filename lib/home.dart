import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'registro.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final supabase = Supabase.instance.client;
  late Stream<List<Map<String, dynamic>>> visitantesStream;
  Key streamKey = UniqueKey();

  @override
  void initState() {
    super.initState();
    _crearStream();
  }

  void _crearStream() {
    visitantesStream = supabase
        .from('visitantes')
        .stream(primaryKey: ['id'])
        .order('hora', ascending: false)
        .execute()
        .map((data) => data.toList());
  }

  void _refreshStream() {
    setState(() {
      _crearStream();       
      streamKey = UniqueKey();    
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lista de Visitantes'),
        backgroundColor: Colors.blue,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshStream, 
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await supabase.auth.signOut(); // Log out the user
              if (context.mounted) {
                Navigator.pushReplacementNamed(context, '/login'); // Redirect to login page
              }
            },
          ),
        ],
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        key: streamKey, 
        stream: visitantesStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final visitantes = snapshot.data ?? [];

          if (visitantes.isEmpty) {
            return const Center(child: Text('No hay visitantes registrados.'));
          }

          return ListView.builder(
            itemCount: visitantes.length,
            itemBuilder: (context, index) {
              final visitante = visitantes[index];
              return ListTile(
                leading: visitante['foto_url'] != null
                    ? CircleAvatar(
                        backgroundImage: NetworkImage(visitante['foto_url']),
                      )
                    : const CircleAvatar(
                        child: Icon(Icons.person),
                      ),
                title: Text(visitante['nombre'] ?? 'Sin nombre'),
                subtitle: Text(visitante['motivo'] ?? 'Sin motivo'),
                trailing: Text(visitante['hora'] != null
                    ? DateTime.parse(visitante['hora'])
                        .toLocal()
                        .toString()
                    : 'Sin hora'),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const RegistroPage()),
          ).then((_) {
            _refreshStream(); 
          });
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
