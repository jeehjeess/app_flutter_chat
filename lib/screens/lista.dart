import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'mapa.dart';

class Lista extends StatefulWidget{
  @override
  ListaState createState() => ListaState();
}

class ListaState extends State<Lista>{
  final CollectionReference _locais =
  FirebaseFirestore.instance.collection("mensagens");

  _abrirMapa(String idLocal){
    Navigator.push(
        context, MaterialPageRoute(builder: (_) => Mapa(idLocal :idLocal))
    );
  }

  _adicionarLocal(){
    Navigator.push(
        context, MaterialPageRoute(builder: (_) => Mapa())
    );
  }

  _excluirLocal(String idLocal){
    _locais.doc(idLocal).delete();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Meus Locais"),),
      floatingActionButton: FloatingActionButton(
        child : Icon(Icons.add),
        backgroundColor: Color(0xff0066cc),
        onPressed: (){
          _adicionarLocal();
        },
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _locais.snapshots(),
        builder: (context, snapshot){
          switch (snapshot.connectionState){
            case ConnectionState.none:
            case ConnectionState.waiting:
              return Center(child: CircularProgressIndicator());
            default:
              List<DocumentSnapshot> locais = [];
              var querySnapshot = snapshot.data;
              if (querySnapshot != null) {
                locais = querySnapshot.docs.toList();
              }
              return Column(
                children: <Widget>[
                  Expanded(child: ListView.builder(
                    itemCount: locais.length,
                    itemBuilder: (context, index){
                      DocumentSnapshot item = locais[index];
                      String titulo = item['senderName'];
                      String idLocal = item.id;
                      return GestureDetector(
                        onTap: (){
                          _abrirMapa(idLocal);
                        },
                        child: Card(
                          child: ListTile(
                            title: Text(titulo),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: <Widget>[
                                GestureDetector(
                                  onTap: (){
                                    _excluirLocal(idLocal);
                                  },
                                  child: Padding(
                                    padding: EdgeInsets.all(8),
                                    child: Icon(
                                        Icons.remove_circle,
                                        color : Colors.red
                                    ),
                                  ),
                                )
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ))
                ],
              );
          }
        },
      ),
    );
  }


}