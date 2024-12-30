import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

Future<void> main() async {
  // Firebase初期化
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(ChatApp());
}

class ChatApp extends StatelessWidget {
  const ChatApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ChatApp',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: LoginPage(),
    );
  }
}

// ログイン画面用Widget
class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  String infoText = '';
  String email = '';
  String password = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
          child: Container(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            TextFormField(
              decoration: InputDecoration(labelText: 'メールアドレス'),
              onChanged: (String value) {
                setState(() {
                  email = value;
                });
              },
            ),
            TextFormField(
              decoration: InputDecoration(labelText: 'パスワード'),
              obscureText: true,
              onChanged: (String value) {
                setState(() {
                  password = value;
                });
              },
            ),
            Container(
              padding: EdgeInsets.all(8),
              child: Text(infoText),
            ),
            Container(
              width: double.infinity,
              child: ElevatedButton(
                  onPressed: () async {
                    try {
                      // メール/パスワードでユーザ登録
                      final FirebaseAuth auth = FirebaseAuth.instance;
                      final result = await auth.createUserWithEmailAndPassword(
                          email: email, password: password);
                      // ユーザー登録に成功した場合、チャット画面に遷移
                      await Navigator.of(context).pushReplacement(
                          MaterialPageRoute(builder: (context) {
                        return ChatPage(result.user!);
                      }));
                    } catch (e) {
                      setState(() {
                        infoText = "登録に失敗しました：${e.toString()}";
                      });
                    }
                  },
                  child: Text('ユーザー登録')),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              child: OutlinedButton(
                  onPressed: () async {
                    try {
                      // メール/パスワードでログイン
                      final FirebaseAuth auth = FirebaseAuth.instance;
                      final result = await auth.signInWithEmailAndPassword(
                          email: email, password: password);
                      // チャット画面に遷移＋ログイン画面を破棄
                      await Navigator.of(context).pushReplacement(
                        MaterialPageRoute(builder: (context) {
                          return ChatPage(result.user!);
                        }),
                      );
                    } catch (e) {
                      setState(() {
                        infoText = "ログインに失敗しました：${e.toString()}";
                      });
                    }
                  },
                  child: Text('ログイン')),
            ),
          ],
        ),
      )),
    );
  }
}

class ChatPage extends StatelessWidget {
  // 引数からユーザー情報を受け取れるようにする
  ChatPage(this.user);
  // ユーザー情報
  final User user;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('チャット'),
        actions: <Widget>[
          IconButton(
              onPressed: () async {
                // ログアウト処理
                await FirebaseAuth.instance.signOut();
                // ログイン画面に遷移＋チャット画面を破棄
                await Navigator.of(context)
                    .pushReplacement(MaterialPageRoute(builder: (context) {
                  return LoginPage();
                }));
              },
              icon: Icon(Icons.logout))
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: EdgeInsets.all(8),
            child: Text('ログイン情報：${user.email}'),
          ),
          Expanded(
              child: StreamBuilder<QuerySnapshot>(
                  // 投稿メッセージ一覧を取得（非同期処理）
                  stream: FirebaseFirestore.instance
                      .collection('posts')
                      .orderBy('date')
                      .snapshots(),
                  builder: (context, snapshot) {
                    // データが取得できた場合
                    if (snapshot.hasData) {
                      final List<DocumentSnapshot> documents =
                          snapshot.data!.docs;
                      // 取得した投稿メッセージ一覧を元にリスト表示
                      return ListView(
                        children: documents.map((document) {
                          return Card(
                            child: ListTile(
                              title: Text(document['text']),
                              subtitle: Text(document['email']),
                              // 自分の投稿メッセージの場合は削除ボタンを表示
                              trailing: document['email'] == user.email
                                  ? IconButton(
                                      onPressed: () async {
                                        await FirebaseFirestore.instance
                                            .collection('posts')
                                            .doc(document.id)
                                            .delete();
                                      },
                                      icon: Icon(Icons.delete))
                                  : null,
                            ),
                          );
                        }).toList(),
                      );
                    }
                    // データが読込中の場合
                    return Center(
                      child: Text('読込中...'),
                    );
                  }))
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          // 投稿画面に遷移
          await Navigator.of(context)
              .push(MaterialPageRoute(builder: (context) {
            return AddPostPage(user);
          }));
        },
        child: Icon(Icons.add),
      ),
    );
  }
}

class AddPostPage extends StatefulWidget {
  // 引数からユーザー情報を受け取れるようにする
  AddPostPage(this.user);
  // ユーザー情報
  final User user;

  @override
  _AddPostPageState createState() => _AddPostPageState();
}

class _AddPostPageState extends State<AddPostPage> {
  // 入力した投稿メッセージ
  String messageText = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('チャット投稿')),
      body: Center(
          child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          // 投稿メッセージ入力
          TextFormField(
            decoration: InputDecoration(labelText: '投稿メッセージ'),
            keyboardType: TextInputType.multiline,
            maxLines: 3,
            onChanged: (String value) {
              setState(() {
                messageText = value;
              });
            },
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            child: ElevatedButton(
                onPressed: () async {
                  final date = DateTime.now().toLocal().toIso8601String();
                  final email = widget.user.email;
                  // 投稿メッセージ用ドキュメント作成
                  await FirebaseFirestore.instance
                      .collection('posts')
                      .doc()
                      .set({'text': messageText, 'email': email, 'date': date});
                  // 一つ前の画面に戻る
                  Navigator.of(context).pop();
                },
                child: Text('投稿')),
          )
        ],
      )),
    );
  }
}
