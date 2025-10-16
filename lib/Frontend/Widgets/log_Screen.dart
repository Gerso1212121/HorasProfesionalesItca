import 'package:flutter/material.dart';
import '../../App/Utils/Utils_ServiceLog.dart';

class LogViewer extends StatelessWidget {
  const LogViewer({super.key});

  Future<List<String>> _getLogs() async {
    return await LogService.readLogs();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Logs'),
      content: FutureBuilder<List<String>>(
        future: _getLogs(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const SizedBox(
              height: 100,
              child: Center(child: CircularProgressIndicator()),
            );
          } else if (snapshot.hasError) {
            return Text('Error: ${snapshot.error}');
          } else {
            final logs = snapshot.data;
            return SizedBox(
              width: double.maxFinite,
              height: 300,
              child: SingleChildScrollView(
                child: SelectableText(
                  logs == null || logs.isEmpty ? 'Sin logs' : logs.join('\n'),
                ),
              ),
            );
          }
        },
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cerrar'),
        ),
        TextButton(
          onPressed: () async {
            await LogService.clearLogs();
            Navigator.of(context).pop();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Logs limpiados')),
            );
          },
          child: const Text('Limpiar'),
        ),
      ],
    );
  }
}
