import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:horas2/Frontend/Routes/RouterGo.dart';

class ProtectedRoute extends StatelessWidget {
  final WidgetBuilder builder;

  const ProtectedRoute({
    Key? key,
    required this.builder,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (!snapshot.hasData || snapshot.data == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            context.go(RouteNames.login);
          });
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final uid = snapshot.data!.uid;

        return FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance
              .collection("estudiantes")
              .doc(uid)
              .get(),
          builder: (context, snap) {

            if (!snap.hasData) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            final doc = snap.data!;

            if (!doc.exists) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                context.go(RouteNames.registerdata);
              });

              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            return builder(context); // Usuario permitido
          },
        );
      },
    );
  }
}
