import 'package:flutter/cupertino.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ChatMessage extends StatelessWidget{
  ChatMessage(this.data, this.mine);
  //mine = true se o usuário estiver logado

  final DocumentSnapshot<Object?> data;
  final bool mine;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(
          vertical: 10, horizontal: 10),
      child: Row(
        children: <Widget>[
          !mine ? Padding(padding: const EdgeInsets.only(right: 16),
            child: CircleAvatar(
              backgroundImage: Image.network(data.get('sendPhotoUrl')).image,
            ),
          ) : Container(),
          Expanded(
              child: Column(
                crossAxisAlignment: mine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: <Widget>[
                  data.get('url') != ""
                      ? Image.network(
                      data.get('url'),
                      width: 150)
                      : Text(data.get('text'),
                      style: TextStyle(fontSize: 16)),
                  Text('Mensagem enviada de ' + data.get("localizacao"),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w100
                  )),
                ],
              )),
          mine ? Padding(padding: const EdgeInsets.only(left: 16),
            child: CircleAvatar(
              backgroundImage: Image.network(data.get('sendPhotoUrl')).image,
            ),
          ) : Container(),
        ],
      ),
    );
  }


}